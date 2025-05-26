CREATE OR REPLACE FUNCTION public.controles_balanceingresoegresos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*  1                  Nombre y apellido de cada afiliado
  2                  Cargo (docente, no docente en caso que sea adherente diga jubilado)
  3                   DNI del afiliado
  4                   Aportes + contribuciones
  5                   Cantidad de beneficiarios a cargo
  6                   Consumos del afiliado y su grupo familiar (total)
  7                    resultado de (col 4 - col 6)
  8                    resultado de (col 4 / (col 5 + 1))
  9                    resultado de (col 6 / (col 5 +1))
*/       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 
IF iftableexists_fisica('temp_balanceingresoegresos_anexo') THEN

DELETE FROM temp_balanceingresoegresos_anexo;

ELSE 

CREATE TABLE temp_balanceingresoegresos_anexo (idprestador bigint,pdescripcion varchar,periodo varchar,importeinternacion double precision,importemedicamento double precision);

END IF;


IF iftableexists_fisica('temp_balanceingresoegresos') THEN

DELETE FROM temp_balanceingresoegresos;

ELSE 

create  table temp_balanceingresoegresos (fechafinos date,nombres varchar,apellido varchar,nrodoctitular varchar,tipodoctitular integer
,cargotipo varchar,aportescontrib double precision,cantidadcarga integer,importereintegrogrupo double precision, importeconsumogrupo double precision,aportesgastos double precision,ingresopromedio double precision,cantidadaportes integer
,gastopromedio double precision, categoriacargo text, mapeocampocolumna text, cantidadordeninternacion integer, cantidadconyugue integer, cantidadcargamayor18 integer );



END IF;


EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--,'1-cod.Convenio#idconvenio@2-Descripcion#cdenominacion@3-Cod.Unidad#idtipounidad@4-Unidad#tudescripcion@5-Importe#monto@6-Inicio Vig.#tvinivigencia@7-Fin Vig.#tvfinvigencia@8-Vigente#vigencia'::text as mapeocampocolumna


--DELETE FROM temp_balanceingresoegresos;
--Cargo a todas las personas potenciales. Pueden estar pasivas pero luego van a decantar segun los aportes o consumos
INSERT INTO temp_balanceingresoegresos (fechafinos,nrodoctitular,tipodoctitular,nombres,apellido,cargotipo) (
SELECT fechafinos,nrodoc,tipodoc,nombres,apellido,case when barra = 31 then 'NO Docente'  when barra = 32 then 'Sosunc' when barra = 35 or barra = 36 then 'Adherente' else 'Docente' END as cargotipo FROM persona WHERE barra >=30 AND barra <=37
);

--Cargo los ingresos de los Agentes Activos de la UNC
UPDATE temp_balanceingresoegresos SET aportescontrib = t.montoaporte,cantidadaportes =T.cantidadaportes, categoriacargo =T.categoriaCargo  FROM (
SELECT nrodoc as nrodoctitu,tipodoc as tipodoctitu/*,barra as barratitu*/,sum(concepto.importe) as montoaporte,count(DISTINCT aporte.mes) as cantidadaportes,text_concatenar(distinct (CASE WHEN NULLVALUE(TT.idcategoria) THEN  idcateg::TEXT ELSE TT.idcategoria::TEXT END)) as categoriaCargo
FROM persona 
NATURAL JOIN cargo 
NATURAL JOIN aporte
JOIN concepto USING(mes,ano,idlaboral)
LEFT JOIN 
(SELECT idcategoria, penrodoc as nrodoc, idtipodocumento as tipodoc FROM  ca.persona  JOIN ca.empleado USING(idpersona) NATURAL JOIN ca.categoriaempleado 
WHERE   nullvalue(cefechafin)) AS TT USING(nrodoc, tipodoc) 
WHERE fechafinlab >= rfiltros.fechadesde /* KR ES para los afil que no estan activos -365::integer*/
AND TO_DATE(concat(lpad(aporte.ano,4,'0'),lpad(aporte.mes,2,'0'),'01'),'YYYYMMDD') >= rfiltros.fechadesde::date
AND TO_DATE(concat(lpad(aporte.ano,4,'0'),lpad(aporte.mes,2,'0'),'01'),'YYYYMMDD') <= rfiltros.fechahasta::date
AND (idconcepto <> 60 AND idconcepto <> -51 AND idconcepto <> 387 AND idconcepto <> 372 AND idconcepto <> 357 AND idconcepto <> 315)
GROUP BY nrodoc,tipodoc

) as t
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;

----Cargo los aportes de los Adherentes 

UPDATE temp_balanceingresoegresos SET aportescontrib = t.montoaporte,cantidadaportes =T.cantidadaportes  FROM (
SELECT nrodoc as nrodoctitu,tipodoc as tipodoctitu,barra as barratitu,sum(importe) as montoaporte,count(*) as cantidadaportes
FROM persona 
NATURAL JOIN aportejubpen 
WHERE TO_DATE(concat(aportejubpen.anio,lpad(aportejubpen.mes,2,'0'),'01'),'YYYYMMDD') >= rfiltros.fechadesde::date
AND TO_DATE(concat(aportejubpen.anio,lpad(aportejubpen.mes,2,'0'),'01'),'YYYYMMDD') <= rfiltros.fechahasta::date

GROUP BY nrodoc,tipodoc
) as t
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;



----- Cargo los gastos del grupo familiar
UPDATE temp_balanceingresoegresos SET importeconsumogrupo = t.importegasto FROM (

SELECT nrodoctitu,tipodoctitu,sum(importegasto) as importegasto FROM (
select distinct nrodoc,tipodoc,nrodoctitu,tipodoctitu,titular from persona
NATURAL JOIN (
SELECT nrodoc,tipodoc,nrodoc as nrodoctitu,tipodoc as tipodoctitu,true as titular FROM afilsosunc 
UNION 
SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu, false as titular FROM benefsosunc 
) as afiliados
WHERE fechafinos >= current_date -365::integer
) as afiliados
NATURAL JOIN (
select nrodoc,tipodoc,sum(importe) as importegasto
from consumo
JOIN ordenesutilizadas USING(nroorden,centro)
WHERE fechauso >=rfiltros.fechadesde
      AND fechauso <=rfiltros.fechahasta
GROUP BY nrodoc,tipodoc

) as consumos
GROUP BY nrodoctitu,tipodoctitu
) as t 
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;


--Determino el consumo de reintegros para el grupo familiar
--importereintegrogrupo


UPDATE temp_balanceingresoegresos SET importereintegrogrupo = t.importegasto FROM (

SELECT nrodoctitu,tipodoctitu,sum(importegasto) as importegasto FROM (
select distinct nrodoc,tipodoc,nrodoctitu,tipodoctitu,titular from persona
NATURAL JOIN (
SELECT nrodoc,tipodoc,nrodoc as nrodoctitu,tipodoc as tipodoctitu,true as titular FROM afilsosunc 
UNION 
SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu, false as titular FROM benefsosunc 
) as afiliados
WHERE fechafinos >= current_date -365::integer
) as afiliados
NATURAL JOIN (

SELECT nrodoc,tipodoc,sum(rimporte) as importegasto
FROM reintegroorden 
NATURAL JOIN consumo
NATURAL JOIN reintegro
WHERE not consumo.anulado AND 
 rfechaingreso >=rfiltros.fechadesde
      AND rfechaingreso <=rfiltros.fechahasta
GROUP BY nrodoc,tipodoc

) as consumos
GROUP BY nrodoctitu,tipodoctitu
) as t 
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;



--Determino la cantidad de Ordenes de Internacion emitirdas para el grupo

UPDATE temp_balanceingresoegresos SET cantidadordeninternacion = t.cantidadordeninternacion FROM (

SELECT nrodoctitu,tipodoctitu,sum(ordeninternacion) as cantidadordeninternacion FROM (
	select distinct nrodoc,tipodoc,nrodoctitu,tipodoctitu,titular from persona
	NATURAL JOIN (
		SELECT nrodoc,tipodoc,nrodoc as nrodoctitu,tipodoc as tipodoctitu,true as titular FROM afilsosunc 
		UNION 
		SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu, false as titular FROM benefsosunc 
		) as afiliados
	WHERE fechafinos >= current_date -365::integer

	) as afiliados
NATURAL JOIN (
select nrodoc,tipodoc,count(*) as ordeninternacion
from orden 
NATURAL JOIN consumo
JOIN ordinternacion USING(nroorden,centro)
WHERE not consumo.anulado AND orden.fechaemision >= rfiltros.fechadesde
      AND  orden.fechaemision <= rfiltros.fechahasta
GROUP BY nrodoc,tipodoc
) as ordenesdeinternacion
GROUP BY nrodoctitu,tipodoctitu
) as t
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;



-- Cargo la carga de familia
UPDATE temp_balanceingresoegresos SET cantidadcarga = t.cantidadcarga - 1 FROM (
SELECT nrodoctitu,tipodoctitu,count(*) as cantidadcarga FROM (
select distinct nrodoc,tipodoc,nrodoctitu,tipodoctitu,titular from persona
NATURAL JOIN (
SELECT nrodoc,tipodoc,nrodoc as nrodoctitu,tipodoc as tipodoctitu,true as titular FROM afilsosunc 
UNION 
SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu, false as titular FROM benefsosunc 
) as afiliados
WHERE fechafinos >= current_date -365::integer ) as grupo
GROUP BY nrodoctitu,tipodoctitu
ORDER BY nrodoctitu ) as t
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;

--Determino la composición del grupo familiar


UPDATE temp_balanceingresoegresos SET cantidadconyugue = t.cantidadconyuge,cantidadcargamayor18= t.cantidadmayor18 FROM (


SELECT nrodoctitu,tipodoctitu,sum(conyuge) as cantidadconyuge,sum(mayor18) as cantidadmayor18 FROM (
select distinct nrodoc,tipodoc,nrodoctitu,tipodoctitu,titular,conyuge,mayor18 from persona
NATURAL JOIN (
SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu, false as titular, CASE WHEN barra = 1 THEN 1 ELSE 0 END as conyuge,CASE WHEN EXTRACT('year' FROM age(current_Date,fechanac)) > 18 AND barra <> 1 THEN 1 ELSE 0 END as mayor18
FROM benefsosunc 
natural join persona  
WHERE barra = 1 OR EXTRACT('year' FROM age(current_Date,fechanac)) >= 18
) as afiliados
WHERE fechafinos >= current_date -365::integer ) as grupo
GROUP BY nrodoctitu,tipodoctitu
ORDER BY nrodoctitu

) as t
WHERE t.nrodoctitu = temp_balanceingresoegresos.nrodoctitular
	AND t.tipodoctitu = temp_balanceingresoegresos.tipodoctitular;






--Son los afiliados activos
--SELECT * FROM temp_balanceingresoegresos WHERE (aportescontrib > 0 OR importeconsumogrupo > 0 ) AND cantidadcarga >=0;
DELETE FROM temp_balanceingresoegresos WHERE nullvalue(cantidadcarga);

--Reemplazo los null por cero
UPDATE temp_balanceingresoegresos SET cantidadconyugue =  CASE WHEN nullvalue(cantidadconyugue) THEN 0 ELSE cantidadconyugue END, cantidadcargamayor18 =CASE WHEN nullvalue(cantidadcargamayor18) THEN 0 ELSE cantidadcargamayor18 END,  cantidadordeninternacion =CASE WHEN nullvalue(cantidadordeninternacion) THEN 0 ELSE cantidadordeninternacion END,importereintegrogrupo =  CASE WHEN nullvalue(importereintegrogrupo) THEN 0 ELSE importereintegrogrupo END,categoriacargo =  CASE WHEN nullvalue(categoriacargo) THEN '' ELSE categoriacargo END;



UPDATE temp_balanceingresoegresos SET aportesgastos =  aportescontrib - (importeconsumogrupo + importereintegrogrupo),ingresopromedio = aportescontrib / (cantidadcarga + 1) , gastopromedio = importeconsumogrupo / (cantidadcarga + 1);


UPDATE temp_balanceingresoegresos SET importeconsumogrupo =  CASE WHEN nullvalue(importeconsumogrupo) THEN 0 ELSE importeconsumogrupo END, aportesgastos =CASE WHEN nullvalue(aportesgastos) THEN 0 ELSE aportesgastos END,  gastopromedio =CASE WHEN nullvalue(gastopromedio) THEN 0 ELSE gastopromedio END;



--Genero el Anexo


INSERT INTO temp_balanceingresoegresos_anexo (idprestador,pdescripcion,periodo,importeinternacion,importemedicamento)  (
SELECT idprestador,pdescripcion,TO_CHAR(mesprestacion, 'MM-YYYY') as periodo,importeinternacion,importemedicamento
 FROM (
select idprestador,date_trunc('month', ffecharecepcion) as mesprestacion,sum(CASE WHEN fidtipoprestacion = 7 THEN fimportepagar ELSE 0 END) as importemedicamento
,sum(CASE WHEN fidtipoprestacion = 12 OR fidtipoprestacion = 2 THEN fimportepagar ELSE 0 END) as importeinternacion
 from factura 
NATURAL JOIN facturaprestaciones
NATURAL JOIN ftipoprestacion
WHERE ffecharecepcion >=  rfiltros.fechadesde AND ffecharecepcion <=  rfiltros.fechahasta
AND not nullvalue(nroordenpago) AND nullvalue(idresumen)
AND (fidtipoprestacion = 12 OR fidtipoprestacion = 2 OR fidtipoprestacion = 7) --Internacion o Intervencion Medicamentos (Farmacia)
GROUP BY idprestador,date_trunc('month', ffecharecepcion)
) as t
NATURAL JOIN prestador
);



return true;
END;
$function$
