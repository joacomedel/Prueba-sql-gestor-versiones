CREATE OR REPLACE FUNCTION public.ampractconvval_configura_arreglapierdeunidad(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los valores de una practica en un convenio */
--SELECT * FROM ampractconvval_configura_arreglapierdeunidad('{fechacorrida=2023-07-01}')

 
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


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


-- Determino las practicas que luego de actualizar unidades pudieron haber perdido su configuracion 
IF iftableexists('practconvval_candidatos') THEN 
DROP TABLE practconvval_candidatos;
DROP TABLE practconvval_anteriores_candidatos;

END IF;
-- Determino las practicas que luego de actualizar unidades pudieron haber perdido su configuracion 

CREATE TABLE practconvval_vigente_candidatos AS (
SELECT *
from practconvval 
where tvvigente AND pcvfechaingreso >= '2023-01-01' 
 AND idasocconv <> 154 
AND (fijoh1 OR fijogs OR fijoh2 OR fijoh3)
AND not (fijoh1 AND fijogs AND fijoh2 AND fijoh3)
AND pcvfechamodifica >= rfiltros.fechacorrida --Fecha de ultima corrida es un parametro
AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) IN (
select idnomenclador,idcapitulo,idsubcapitulo,idpractica from nomencladoruno 
where pmhonorario1 <> 0 and (pmcantgastos <> 0 OR pmhonorario2 <> 0 OR pmhonorario3 <> 0) )

);

--Version anterior de los valores configurados 
CREATE TABLE practconvval_anteriores_candidatos AS (
SELECT *
FROM practconvval
NATURAL JOIN (
select idnomenclador,idcapitulo,idsubcapitulo,idpractica,idasocconv,pcvsis as pcvsisant,pcvfechainicio as pcvfechainicand,fijoh1 as fijoh1hoy,fijogs as fijogshoy,fijoh2 as fijoh2hoy,fijoh3 as fijoh3hoy,idpractconvval as idpractconvvalhoy
FROM practconvval_vigente_candidatos
) as candidatos
WHERE not tvvigente AND pcvsisant = pcvsis 
AND (fijoh1 <> fijoh1hoy OR fijoh2 <> fijoh2hoy OR fijoh3 <> fijoh3hoy OR fijogs <> fijogshoy)
);

--Modifico la configuracion de valores para que quede como estaba en la version anterior.

--SELECT DISTINCT practconvval.idnomenclador ,practconvval.idcapitulo,practconvval.idsubcapitulo ,practconvval.idpractica ,practconvval.idasocconv,practconvval.fijoh1,cc.fijoh1,practconvval.h1,cc.h1,practconvval.fijoh2,cc.fijoh2,practconvval.h2,cc.h2,practconvval.fijoh3,cc.fijoh3,practconvval.h3,cc.h3,practconvval.fijogs,cc.fijogs,practconvval.gasto,cc.gasto,practconvval.pcvobs ,practconvval.idpractconvval ,practconvval.internacion,practconvval.pcvsis 
UPDATE practconvval SET pcvobs = 'Arreglo Malapi con proceso ampractconvval_configura_arreglapierdeunidad',
pcvfechamodifica = now(),fijoh1 = cc.fijoh1,fijoh2 = cc.fijoh2,fijoh3 = cc.fijoh3,fijogs = cc.fijogs,
h1 = cc.h1,h2 = cc.h2,h3 = cc.h3,gasto = cc.gasto
-- FROM practconvval,practconvval_anteriores_candidatos as cc
FROM practconvval_anteriores_candidatos as cc
WHERE practconvval.tvvigente  
AND practconvval.idpractconvval = cc.idpractconvvalhoy
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
