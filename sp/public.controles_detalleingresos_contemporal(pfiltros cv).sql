CREATE OR REPLACE FUNCTION public.controles_detalleingresos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
/*  1                 Nombre y apellido de cada afiliado
  2                   Cargo (docente, no docente en caso que sea adherente diga jubilado)
  3                   DNI del afiliado
  4                   Aportes + contribuciones
  5                   valor de ipc para perido de mes/año 
  6                   Mes/Año del aporte
  7                   Cantidad de beneficiarios a cargo
  8                   fechafinos actual
  9                   aporte + contribucion segun ipc 
  */       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

IF iftableexists_fisica('temp_detalleingresos') THEN

DELETE FROM temp_detalleingresos;

ELSE 

create  table temp_detalleingresos (fechafinos date,nombres varchar,apellido varchar,nrodoctitular varchar,tipodoctitular integer
,cargotipo varchar,aportescontrib double precision,cantidadcarga integer,mes integer,anio integer,mesanio varchar,
categoriacargo text, mapeocampocolumna text, cantidadconyugue integer, cantidadcargamayor18 integer,
								   ipcmes double precision, aportescontribipc double precision);

END IF;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
--,'1-cod.Convenio#idconvenio@2-Descripcion#cdenominacion@3-Cod.Unidad#idtipounidad@4-Unidad#tudescripcion@5-Importe#monto@6-Inicio Vig.#tvinivigencia@7-Fin Vig.#tvfinvigencia@8-Vigente#vigencia'::text as mapeocampocolumna
--Cargo a todas las personas potenciales. Pueden estar pasivas pero luego van a decantar segun los aportes o consumos
INSERT INTO temp_detalleingresos (fechafinos,nrodoctitular,tipodoctitular,nombres,apellido,cargotipo) (
SELECT fechafinos,nrodoc,tipodoc,nombres,apellido,case when barra = 31 then 'NO Docente'  when barra = 32 then 'Sosunc' when barra = 35 or barra = 36 then 'Adherente' else 'Docente' END as cargotipo 
	FROM persona WHERE barra >=30 AND barra <=37
);
--Cargo los ingresos de los Agentes Activos de la UNC

INSERT INTO temp_detalleingresos (fechafinos,nrodoctitular,tipodoctitular,nombres,apellido,cargotipo,aportescontrib,categoriacargo,mes,anio,mesanio)
(
SELECT fechafinos,nrodoctitular,tipodoctitular,nombres,apellido,cargotipo, t.montoaporte, t.categoriaCargo,t.mes,t.anio, concat(t.mes,'-',t.anio) 
FROM temp_detalleingresos
JOIN 
(
SELECT nrodoc as nrodoctitu,tipodoc as tipodoctitu,sum(concepto.importe) as montoaporte,aporte.ano as anio,aporte.mes as mes,text_concatenarsinrepetir(CASE WHEN NULLVALUE(idcateg) THEN  TT.idcategoria::TEXT ELSE  idcateg::TEXT END) as categoriaCargo
FROM persona 
NATURAL JOIN cargo 
NATURAL JOIN aporte
JOIN concepto USING(mes,ano,idlaboral)
LEFT JOIN
(SELECT idcategoria, penrodoc as nrodoc, idtipodocumento as tipodoc FROM  ca.persona  JOIN ca.empleado USING(idpersona) NATURAL JOIN ca.categoriaempleado 
WHERE   nullvalue(cefechafin)) AS TT USING(nrodoc, tipodoc) 

WHERE TO_DATE(concat(lpad(aporte.ano,4,'0'),lpad(aporte.mes,2,'0'),'01'),'YYYYMMDD') >= rfiltros.fechadesde::date
AND TO_DATE(concat(lpad(aporte.ano,4,'0'),lpad(aporte.mes,2,'0'),'01'),'YYYYMMDD') <= rfiltros.fechahasta::date
AND (idconcepto <> 60 AND idconcepto <> -51 AND idconcepto <> 387 AND idconcepto <> 372 AND idconcepto <> 357 AND idconcepto <> 315)
GROUP BY nrodoc,tipodoc,aporte.ano,aporte.mes

) as t ON nrodoctitu = nrodoctitular AND tipodoctitular = tipodoctitu

);


----Cargo los aportes de los Adherentes 
INSERT INTO temp_detalleingresos (fechafinos,nrodoctitular,tipodoctitular,nombres,apellido,cargotipo,aportescontrib,categoriacargo,mes,anio,mesanio)
(
SELECT fechafinos,nrodoctitular,tipodoctitular,nombres,apellido,cargotipo, t.montoaporte, t.categoriaCargo,t.mes,t.anio, concat(t.mes,'-',t.anio) 
FROM temp_detalleingresos
JOIN 
(
SELECT nrodoc as nrodoctitu,tipodoc as tipodoctitu,barra as barratitu,sum(importe) as montoaporte,aportejubpen.anio as anio,aportejubpen.mes,'JUB' as categoriaCargo
FROM persona 
NATURAL JOIN aportejubpen 
WHERE TO_DATE(concat(aportejubpen.anio,lpad(aportejubpen.mes,2,'0'),'01'),'YYYYMMDD') >= rfiltros.fechadesde::date
AND TO_DATE(concat(aportejubpen.anio,lpad(aportejubpen.mes,2,'0'),'01'),'YYYYMMDD') <= rfiltros.fechahasta::date
GROUP BY nrodoc,tipodoc,aportejubpen.anio,aportejubpen.mes
) as t ON nrodoctitu = nrodoctitular AND tipodoctitular = tipodoctitu

);

DELETE FROM temp_detalleingresos WHERE nullvalue(aportescontrib) ;

-- Cargo la carga de familia
UPDATE temp_detalleingresos SET cantidadcarga = t.cantidadcarga - 1 FROM (
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
WHERE t.nrodoctitu = temp_detalleingresos.nrodoctitular
	AND t.tipodoctitu = temp_detalleingresos.tipodoctitular;

--Determino la composición del grupo familiar

UPDATE temp_detalleingresos SET cantidadconyugue = t.cantidadconyuge,cantidadcargamayor18= t.cantidadmayor18 FROM (

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
WHERE t.nrodoctitu = temp_detalleingresos.nrodoctitular
	AND t.tipodoctitu = temp_detalleingresos.tipodoctitular;

--Son los afiliados activos
--SELECT * FROM temp_balanceingresoegresos WHERE (aportescontrib > 0 OR importeconsumogrupo > 0 ) AND cantidadcarga >=0;
--LETE FROM temp_detalleingresos WHERE nullvalue(cantidadcarga);

--Cargo el valor del ipc aplicado

UPDATE temp_detalleingresos SET ipcmes = ipc.ipcaplicado, aportescontribipc = temp_detalleingresos.aportescontrib * ipc.ipcaplicado
FROM controles_ipc  as ipc
WHERE ipc.mesnumero = temp_detalleingresos.mes 
AND ipc.anionumero =temp_detalleingresos.anio;

--Reemplazo los null por cero
UPDATE temp_detalleingresos SET cantidadconyugue =  CASE WHEN nullvalue(cantidadconyugue) THEN 0 ELSE cantidadconyugue END
, cantidadcargamayor18 =CASE WHEN nullvalue(cantidadcargamayor18) THEN 0 ELSE cantidadcargamayor18 END
,categoriacargo=  CASE WHEN nullvalue(categoriacargo) THEN '' ELSE categoriacargo END;

return true;
END;
$function$
