CREATE OR REPLACE FUNCTION public.asistencial_pvxchistorico_usandofechavigencia_contabla(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--cursor 
  cpvxchistoricototal REFCURSOR;
  cpvxchistorico REFCURSOR;
--record
  rpvxchistoricototal  record;
  rfiltros RECORD;
  runapractica RECORD;
--VARIABLES 
  contadorordenh INTEGER;

BEGIN
--psql -h 127.0.0.1 -d SOSSIGES_BETA -U postgres -c "SELECT * FROM asistencial_pvxchistorico_usandofechavigencia_contabla('{lala=si}');";
/*
--Crea la tabla de practicas que son con unidades
CREATE TABLE practicasconunidades_14112023 AS (
SELECT DISTINCT idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,internacion
from practconvval 
where tvvigente AND pcvfechaingreso >= '2023-01-01' 
AND idasocconv <> 154 

AND (not fijoh1 OR not fijogs OR not fijoh2 OR not fijoh3)
)

INSERT INTO practicasasociacionarreglahisto(idasocconv,idnomenclador,tvinivigencia)  
(
select distinct t.idasocconv,idnomenclador, tvinivigencia
 from practicasconunidades_14112023  as t
 JOIN asocconvenio as x ON t.idasocconv = x.idasocconv 
 JOIN tablavalores as tv on x.idconvenio = tv.idconvenio
 WHERE idnomenclador = '07' AND t.idasocconv not in (122,127)
AND tvinivigencia >= '2023-06-01' AND idtipounidad IN(140)  
order by tvinivigencia
)



CREATE TABLE practicasconunidades_12072023 AS (
SELECT DISTINCT idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,internacion
from practconvval 
where tvvigente AND pcvfechaingreso >= '2023-01-01' 
AND idasocconv <> 154 
AND (not fijoh1 OR not fijogs OR not fijoh2 OR not fijoh3)
)

--Elimino las que estan mal
DELETE FROM  practicavaloresxcategoriahistorico    WHERE 
--(pvxchfechafin = '2023-05-08 17:22:16.787582' OR pvxchfechafin = '2023-07-08 17:23:50.695215') AND  
not nullvalue(pvxchfechainivigencia) 
AND pvxchfechainivigencia >= '2022-10-01'
AND pvxchfechainivigencia = pvxchfechafinvigencia
--AND pvxchordenhistorico = 2
AND (idasocconv,idsubcapitulo,idcapitulo,idpractica,idsubespecialidad,internacion) IN (SELECT DISTINCT idasocconv,idsubcapitulo,idcapitulo,idpractica,idnomenclador,internacion
from practicasconunidades_12072023 )
ORDER BY pvxchfechainivigencia DESC; 

--Crea la tabla para saber que ordenar
CREATE TABLE practicasasociacionarreglahisto AS 
(
select distinct idasocconv,idnomenclador, null as procesado
 from practicasconunidades_12072023 
)

INSERT INTO practicasasociacionarreglahisto AS 
(
select distinct idasocconv,idnomenclador, null as procesado
 from practicasconunidades_14112023 
)

*/
   EXECUTE sys_dar_filtros($1) INTO rfiltros;
   RAISE NOTICE 'Los filtros con (%)',rfiltros;
  OPEN cpvxchistoricototal FOR select distinct  idnomenclador,idasocconv,concat('{idasocconv =', idasocconv,' ,fechavigencia =',tvinivigencia,' }') as param
  							from practicasasociacionarreglahisto 
							where nullvalue(procesado) 
							order by idnomenclador
							; 
  FETCH cpvxchistoricototal into rpvxchistoricototal;
  WHILE FOUND LOOP
      RAISE NOTICE 'Adentro con (%)',rpvxchistoricototal;
	  PERFORM calcularvalorespracticaxcategoria_solohisto(rpvxchistoricototal.param);
	  	
  FETCH cpvxchistoricototal into rpvxchistoricototal ;
  END LOOP;
  CLOSE cpvxchistoricototal;
 RAISE NOTICE 'Ahora arreglo re ordenos los historicos (%)',rfiltros;
  OPEN cpvxchistoricototal FOR select distinct idnomenclador,idasocconv,concat('{idnomenclador=^',idnomenclador,',internacion=no,idasocconv=',idasocconv,'}') as param,
concat('{idnomenclador=^',idnomenclador,',internacion=si,idasocconv=',idasocconv,'}') as param_1
  							from practicasasociacionarreglahisto 
							where nullvalue(procesado) 
							order by idnomenclador
							; 
  FETCH cpvxchistoricototal into rpvxchistoricototal;
  WHILE FOUND LOOP
      RAISE NOTICE 'Adentro con (%)',rpvxchistoricototal;
	  PERFORM asistencial_pvxchistorico_usandofechavigencia(rpvxchistoricototal.param);
	  PERFORM asistencial_pvxchistorico_usandofechavigencia(rpvxchistoricototal.param_1);
	  UPDATE practicasasociacionarreglahisto SET procesado = now() 
	  	WHERE idnomenclador = rpvxchistoricototal.idnomenclador 
		AND idasocconv = rpvxchistoricototal.idasocconv;
		
  FETCH cpvxchistoricototal into rpvxchistoricototal ;
  END LOOP;
  CLOSE cpvxchistoricototal;
--El Historico 1 es el que tiene que quedar vigente, el resto no.

 
   return  'OK'  ;

END;
$function$
