CREATE OR REPLACE FUNCTION public.ampractconvval_configura_eliminacambiovalor(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los valores de una practica en un convenio */
--SELECT * FROM ampractconvval_configura_eliminacambiovalor('{pcvfechafin =2023-06-01,fechacorrida=2023-07-01}')

 
DECLARE
	alta refcursor; -- FOR SELECT * FROM temppractconvval WHERE nullvalue(temppractconvval.error) ORDER BY temppractconvval.idasocconv;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	rconvenio RECORD;
	resultado boolean;
	idconvenio bigint;
	verificar RECORD;
	deno_anterior bigint;
	idpracticavalor bigint;
	errores boolean;
        rusuario RECORD; 
		 rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- Determino las practicas que luego de actualizar unidades pudieron haber perdido su configuracion 
IF iftableexists('practconvval_fechas_candidatos') THEN 
DROP TABLE practconvval_fechas_candidatos;
DROP TABLE practconvval_fechas_debenquedarvigentes;
DROP TABLE practconvval_anteriores_candidatos_fijos;

END IF;


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

CREATE TABLE practconvval_fechas_candidatos AS (
select distinct nvfpmfechaproceso,fechainiciovigencia from nomenclador_valorfijo_para_migrar where fechainiciovigencia >= rfiltros.pcvfechafin order by nvfpmfechaproceso 

);


--Determino las fechas de creacion de los valores en practconvval

create table practconvval_anteriores_candidatos_fijos as 
(
SELECT *
FROM practconvval 
where idasocconv <> 154 and not tvvigente
AND pcvsis in ( 
select nvfpmfechaproceso from practconvval_fechas_candidatos
)
and pcvsis > pcvfechaingreso
AND pcvfechafin = rfiltros.pcvfechafin 
order by pcvfechaingreso 
);


--timestamp de cuando se pusieron en vigencia los valores calculados
-- se usa para eliminar el hisotirico y restaurar en practicavalores

create table practconvval_fechas_debenquedarvigentes as (
select distinct fechamodif from practicavaloresmodificados as x
JOIN ( SELECT 	idcapitulo,idsubcapitulo,idpractica,idnomenclador as idsubespecialidad,internacion,idasocconv,pcvfechainicio,pcvsis
from practconvval 
where idasocconv <> 154 and not tvvigente
AND pcvsis in ( 
select nvfpmfechaproceso from practconvval_fechas_candidatos
 ) ) as t on  (t.idcapitulo = x.idcapitulo and t.idsubcapitulo = x.idsubcapitulo and t.idpractica = x.idpractica and t.idsubespecialidad = x.idsubespecialidad and t.internacion = x.internacion and t.idasocconv = x.idasocconv and t.pcvfechainicio = x.pvmfechainivigencia)
WHERE fechamodif > pcvsis 
);

-- Elimino de practicavalores

DELETE FROM practicavalores 
--select * from practicavalores 
WHERE (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,internacion,idasocconv) IN 
(

select distinct idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,internacion,idasocconv
from practicavaloresmodificados as x where fechamodif in (
select fechamodif from practconvval_fechas_debenquedarvigentes 
) 
--and (idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, internacion)=(12, 25, '01', 41, 1011, false)
group by idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, internacion
);

--Elimino las que ya no estan vigentes, no deberia haber ninguno...
--DELETE FROM practicavalores 
--select * from practicavalores 
--WHERE (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,internacion,idasocconv,pvfechainivigencia) IN 
--(
--SELECT 	idcapitulo,idsubcapitulo,idpractica,idnomenclador as idsubespecialidad,round(h1::numeric,2) as importe,internacion,idasocconv,pcvfechainicio
--from practconvval 
--where idasocconv <> 154 and not tvvigente
--AND pcvsis in ( 
--select nvfpmfechaproceso from practconvval_fechas_candidatos
--)
--);
--
-- Elimino las que quedaron vigentes
--DELETE FROM practicavalores 
--select * from practicavalores 
--WHERE (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,internacion,idasocconv,pvfechainivigencia) IN 
--(
--SELECT 	idcapitulo,idsubcapitulo,idpractica,idnomenclador as idsubespecialidad,round(h1::numeric,2) as importe,internacion,idasocconv,pcvfechainicio
--from practconvval 
--where idasocconv <> 154 and tvvigente
--AND pcvsis in ( 
--select nvfpmfechaproceso from practconvval_fechas_candidatos
--)
--);

--DELETE FROM practicavalores 
--select * from practicavalores 
--WHERE (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,internacion,idasocconv,pvfechainivigencia) IN 
--(
--SELECT 	idcapitulo,idsubcapitulo,idpractica,idnomenclador as idsubespecialidad,h1 as importe,internacion,idasocconv,pcvfechainicio
--from practconvval 
--where idasocconv <> 154 and tvvigente
--AND pcvsis in ( 
--select nvfpmfechaproceso from practconvval_fechas_candidatos
--)
--);

--inserto en practica valores los valores que estaban vigentes antes de insert los valores
INSERT INTO practicavalores (idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,internacion,idasocconv,pvfechainivigencia) (
select distinct idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,min(importe),internacion,idasocconv,min(pvmfechainivigencia) 
from practicavaloresmodificados as x where fechamodif in (
select fechamodif from practconvval_fechas_debenquedarvigentes 
) 
--and (idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, internacion)=(12, 25, '01', 41, 1011, false)
group by idsubespecialidad, idcapitulo, idsubcapitulo, idpractica, idasocconv, internacion

);

-- Elimino el valor de practicavaloresxcategoria

--select distinct idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,internacion,idasocconv,	pvxcfechainivigencia,	
--pvxcfechafinvigencia ,pvxcfechaini
DELETE
from practicavaloresxcategoria as x where pvxcfechaini in (
select fechamodif from practconvval_fechas_debenquedarvigentes 
);

-- Elimino practicavaloresxcategoriahistorico 

--select distinct idcapitulo,idsubcapitulo,idpractica,idsubespecialidad,importe,internacion,idasocconv,	pvxchfechaini,		pvxchfechainivigencia --,pvxchfechafin,pvxchordenhistorico
DELETE
from practicavaloresxcategoriahistorico as x where pvxchfechaini in (
select fechamodif from practconvval_fechas_debenquedarvigentes 
);

--Elimino los datos de practconvval
-- Los que salieron de vigencia
DELETE 
--SELECT count(*)
FROM practconvval 
where idasocconv <> 154 and not tvvigente
AND pcvsis in ( 
select nvfpmfechaproceso from practconvval_fechas_candidatos
);

-- Los que quedaron en vigencia
DELETE 
--SELECT count(*)
FROM practconvval 
where idasocconv <> 154 and tvvigente
AND pcvsis in ( 
select nvfpmfechaproceso from practconvval_fechas_candidatos
);

--Modifico la configuracion de valores para que quede como estaba en la version anterior.
-- terminar para valores fijos
--SELECT DISTINCT practconvval.idnomenclador ,practconvval.idcapitulo,practconvval.idsubcapitulo ,practconvval.idpractica ,practconvval.idasocconv,practconvval.fijoh1,cc.fijoh1,practconvval.h1,cc.h1,practconvval.fijoh2,cc.fijoh2,practconvval.h2,cc.h2,practconvval.fijoh3,cc.fijoh3,practconvval.h3,cc.h3,practconvval.fijogs,cc.fijogs,practconvval.gasto,cc.gasto,practconvval.pcvobs ,practconvval.idpractconvval ,practconvval.internacion,practconvval.pcvsis 
UPDATE practconvval SET pcvobs = 'Arreglo Malapi con ampractconvval_configura_eliminacambiovalor',
pcvfechamodifica = now(),tvvigente = true,pcvfechafin = null
-- FROM practconvval,practconvval_anteriores_candidatos_fijos as cc
FROM practconvval_anteriores_candidatos_fijos as cc
WHERE NOT practconvval.tvvigente  
AND practconvval.idpractconvval = cc.idpractconvval
AND practconvval.idnomenclador = cc.idnomenclador
AND practconvval.idcapitulo = cc.idcapitulo
AND practconvval.idsubcapitulo = cc.idsubcapitulo
AND practconvval.idpractica = cc.idpractica
AND practconvval.idasocconv = cc.idasocconv
AND practconvval.internacion = cc.internacion;

--Hay que volver a correr el procedimiento calcular valores practica masivo
--PERFORM  calcularvalorespractica_masivo_completo(concat('{ fechadesde=',current_date,'}'));

resultado = 'true';
RETURN resultado;
END;
$function$
