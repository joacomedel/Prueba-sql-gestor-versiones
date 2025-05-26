CREATE OR REPLACE FUNCTION public.sys_alta_modifica_auditoria_vincular_orden(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
  vseaudito BOOLEAN;
  respuesta VARCHAR;
  vusuario INTEGER; 
  vtipoprestacion INTEGER; 
  verifica BOOLEAN;
  elidfichamedica BIGINT;
  elidfichamedicaitem BIGINT; 
  elidcentroidfichamedica INTEGER;
  elidnomenclador VARCHAR;
  elidcapitulo VARCHAR;
  elidsubcapitulo VARCHAR;
  elidpractica VARCHAR;
  elidfichamedicaitempendiente BIGINT;
  elidfichamedicaitempendientecentro INTEGER;

--RECORD
  rfichamedicaitem RECORD;
  rfiltros RECORD;
  rverifica RECORD; 
  ritem RECORD;
  rorden RECORD;

--CURSOR
  cursoritem refcursor;
  cursororden refcursor;

BEGIN
--SELECT sys_alta_modifica_auditoria_vincular_orden('{cualcontrol=porpractica}')
 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_ordenesparacontrolar_conauditoria AS (
SELECT
CASE WHEN not nullvalue(tipoafiliadopor) THEN tipoafiliadopor WHEN not nullvalue(tipoafiliado) THEN tipoafiliado ELSE 'sincontrol' END as tipoafiliado,
idrecibo,CONCAT(idrecibo,'-',centro) AS elidrecibo, nroorden, centro, CONCAT(nroorden,'-',centro) AS elidorden, CONCAT(apellido, ', ', nombres) as elafiliado
,diagnostico, consumo.nrodoc, consumo.tipodoc , to_char(fechaemision, 'DD/MM/YYYY hh:mm:ss') as fechaemision
FROM ordenrecibo
NATURAL JOIN consumo
NATURAL JOIN orden
NATURAL JOIN cambioestadosorden
NATURAL JOIN ordenonlineinfoextra
NATURAL JOIN ordvalorizada
NATURAL JOIN persona
LEFT JOIN ( SELECT nroorden, centro FROM itemvalorizada NATURAL JOIN iteminformacion WHERE iditemestadotipo=1 GROUP BY nroorden, centro) as t USING(nroorden, centro)
LEFT JOIN (select DISTINCT nrodoc,tipodoc::integer,CASE when pcpcobertura100 = 'si' then 'al100' else pcpcobertura100 end as tipoafiliado,pcpfechaingreso as fechaingresoplan,pcpfechafin as fechasalidaplan
from persona
natural join plancobpersona
natural join plancoberturaconporcentaje
WHERE pcpcobertura100 = 'si' AND (nullvalue(pcpfechafin) OR pcpfechafin >= current_date)
) as cobertura100 USING(nrodoc,tipodoc)

LEFT JOIN (
SELECT concat('porpractica_',codigocob) as tipoafiliadopor, nroorden, centro,tipo
FROM ( SELECT nrodoc,tipodoc,concat(idplancoberturas,'_',pcppcodigopractica) as codigocob, split_part(pcppcodigopractica,'.',1) as idnomenclador,split_part(pcppcodigopractica,'.',2) as idcapitulo
,split_part(pcppcodigopractica,'.',3) as idsubcapitulo,split_part(pcppcodigopractica,'.',4) as idpractica
,pcpfechaingreso as fechaingresoplan,pcpfechafin as fechasalidaplan
FROM persona
natural join plancobpersona pcp
natural join plancoberturaconporcentaje
WHERE pcppdesdepractica AND fechafinos >= current_date AND (nullvalue(pcpfechafin) OR pcpfechafin >= current_date)
) as planporpractica
NATURAL JOIN consumo
NATURAL JOIN orden
NATURAL JOIN ordvalorizada
NATURAL JOIN itemvalorizada
NATURAL JOIN item
NATURAL JOIN cambioestadosorden
WHERE idasocconv=127 AND idordenventaestadotipo= 1 AND nullvalue(ceofechafin) AND tipo=56

) as porpractica USING( nroorden, centro,tipo)
WHERE idasocconv=127 AND idordenventaestadotipo= 1 AND nullvalue(ceofechafin) AND tipo=56 AND nullvalue(t.nroorden) AND true AND barra < 100
ORDER BY nrodoc,nroorden, fechaemision
);



 vusuario = sys_dar_usuarioactual();
 --Creo la tabla temporal para auditar la practica
 CREATE TEMP TABLE TEMP_ALTA_MODIFICA_FICHA_MEDICA (  IDFICHAMEDICA INTEGER,  IDCENTROFICHAMEDICA INTEGER,  IDFICHAMEDICAITEM INTEGER,  IDCENTROFICHAMEDICAITEM INTEGER,  IDFICHAMEDICAITEMPENDIENTE INTEGER,  IDCENTROFICHAMEDICAITEMPENDIENTE INTEGER,  FMIFECHAAUDITORIA DATE,  FMICANTIDAD INTEGER, FMIDESCRIPCION VARCHAR,  IDPRESTADOR BIGINT,  IDITEM BIGINT,  IDITEMESTADOTIPO INTEGER, IDUSUARIO INTEGER, IICOBERTURASOSUNCSUGERIDA FLOAT, OPERACION VARCHAR, LAPRACTICA VARCHAR, NRODOC VARCHAR,  TIPODOC INTEGER, IDAUDITORIATIPO INTEGER,  NROORDEN BIGINT, CENTRO INTEGER,  COBERTURA DOUBLE PRECISION, IIERROR VARCHAR) ;

vseaudito = false;
respuesta = 'Control por Practica: ';
--MaLapi 25-03-2022 Son ordenes, que se deben controlar en el marco de un plan de cobertura en alguna de sus practias
--MaLapi 30-05-2022 Se agrega la opcion de filtrar cual control se quiere realizar... no los hace a todos juntos.
IF rfiltros.cualcontrol = 'porpractica' THEN

 OPEN cursororden FOR SELECT * from temp_ordenesparacontrolar_conauditoria WHERE tipoafiliado  ilike 'porpractica%' ;
 FETCH cursororden INTO rorden;
 WHILE  found LOOP
  
 -- Pongo los items que deben ser modificados en su auditoria, como pendiente de auditoria, es decir, en estado 1
  UPDATE  iteminformacion SET iditemestadotipo = 1 WHERE (iditem,centro) IN (
 	SELECT iditem,centro
       FROM ( SELECT nrodoc,tipodoc,concat(idplancoberturas,'-',pc.descripcion,'_',pcppcodigopractica) as codigocob, split_part(pcppcodigopractica,'.',1) as idnomenclador,split_part(pcppcodigopractica,'.',2) as idcapitulo 
             ,split_part(pcppcodigopractica,'.',3) as idsubcapitulo,split_part(pcppcodigopractica,'.',4) as idpractica 
             ,pcpfechaingreso as fechaingresoplan,pcpfechafin as fechasalidaplan,pccpvalor
             FROM persona
             natural join plancobpersona pcp
			 NATURAL JOIN plancobertura pc
             natural join plancoberturaconporcentaje
             WHERE  pcppdesdepractica AND fechafinos >= current_date AND (nullvalue(pcpfechafin) OR pcpfechafin >= current_date)
             ) as planporpractica 
	   NATURAL JOIN consumo
       NATURAL JOIN orden
       NATURAL JOIN ordvalorizada
       NATURAL JOIN itemvalorizada
	   NATURAL JOIN item
	   NATURAL JOIN cambioestadosorden
	   JOIN  iteminformacion USING(iditem,centro)
      WHERE idasocconv=127 AND idordenventaestadotipo= 1 AND nullvalue(ceofechafin) AND tipo=56
	   AND fechaemision >= fechaingresoplan AND (fechaemision <= fechasalidaplan OR nullvalue(fechasalidaplan))
	   AND nroorden = rorden.nroorden AND centro = rorden.centro
	   );
 
 respuesta = concat(respuesta,'*',rorden.nroorden,'-',rorden.centro);
 DELETE FROM TEMP_ALTA_MODIFICA_FICHA_MEDICA;
-- Audito cada item que tiene una cobertura diferenciada  

INSERT INTO temp_alta_modifica_ficha_medica (operacion,iicoberturasosuncsugerida,iditemestadotipo,idfichamedica,idcentrofichamedica,iditem
											 ,idfichamedicaitempendiente,idcentrofichamedicaitempendiente,fmifechaauditoria,fmicantidad
											 ,lapractica,nroorden, centro,nrodoc,tipodoc,idauditoriatipo,cobertura,iierror) 
--VALUES ('aprobar','100',1,31108,1,988711,21874,1,now(),1,NULL,NULL,NULL,'07.66.27.2734',1293254,1,'29339689',1,5,'100','La practica es autorizada. ');
(
SELECT 'aprobar',pccpvalor*100 as iicoberturasosuncsugerida,iditemestadotipo,fm.idfichamedica,fm.idcentrofichamedica,iditem,idfichamedicaitempendiente,idcentrofichamedicaitempendiente,now() as fmifechaauditoria,cantidad as fmicantidad
	,concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) as lapractica,nroorden,centro,consumo.nrodoc,consumo.tipodoc,5 as idauditoriatipo,pccpvalor*100 as cobertura, concat('La practica es autorizada. ',codigocob) as iierror
       FROM ( SELECT nrodoc,tipodoc,concat(idplancoberturas,'-',pc.descripcion,'_',pcppcodigopractica) as codigocob, split_part(pcppcodigopractica,'.',1) as idnomenclador,split_part(pcppcodigopractica,'.',2) as idcapitulo 
             ,split_part(pcppcodigopractica,'.',3) as idsubcapitulo,split_part(pcppcodigopractica,'.',4) as idpractica 
             ,pcpfechaingreso as fechaingresoplan,pcpfechafin as fechasalidaplan,pccpvalor
             FROM persona
             natural join plancobpersona pcp
			 NATURAL JOIN plancobertura pc
             natural join plancoberturaconporcentaje
             WHERE  pcppdesdepractica AND fechafinos >= current_date AND (nullvalue(pcpfechafin) OR pcpfechafin >= current_date)
             ) as planporpractica 
	   NATURAL JOIN consumo
       NATURAL JOIN orden
       NATURAL JOIN ordvalorizada
       NATURAL JOIN itemvalorizada
	   NATURAL JOIN item
	   NATURAL JOIN cambioestadosorden
	   NATURAL JOIN fichamedica as fm 
	   LEFT JOIN fichamedicaitempendiente as fmip ON (fm.nrodoc = fmip.nrodoc AND fmip.tipodoc = fm.tipodoc AND fmip.idcentrofichamedica = fm.idcentrofichamedica AND fmip.idauditoriatipo = fm.idauditoriatipo AND 
	      fmip.nroreintegro = orden.nroorden AND fmip.idcentroregional = orden.centro)
	   JOIN  iteminformacion USING(iditem,centro)
       WHERE idasocconv=127 AND idordenventaestadotipo= 1 AND nullvalue(ceofechafin) AND tipo=56
	   AND fechaemision >= fechaingresoplan AND (fechaemision <= fechasalidaplan OR nullvalue(fechasalidaplan))
	   AND fm.idauditoriatipo = 5
	   AND nroorden = rorden.nroorden AND centro = rorden.centro
);
 
 -- Llamo a auditar la orden
 
 PERFORM alta_modifica_auditoria_vincular_orden();

-- Llamo al sp que recalcula los valores
--expendio_recalcularimporteorden

 PERFORM expendio_recalcularimporteorden(concat('{','nroorden=',rorden.nroorden,', centro=',rorden.centro,'}')); 
 
-- La dejo lista para facturar
 PERFORM expendio_cambiarestadoorden(rorden.nroorden, rorden.centro, 9);

FETCH cursororden INTO rorden;
END LOOP;
CLOSE cursororden;

END IF;

respuesta = concat(respuesta,' | Sin Control: ');
--MaLapi 29-03-2022 Son ordenes, que no hace falta controlar, pues la persona no tiene planes de cobertura especiales
--MaLapi 30-05-2022 Se agrega la opcion de filtrar cual control se quiere realizar... no los hace a todos juntos.
IF rfiltros.cualcontrol = 'sincontrol' THEN

OPEN cursororden FOR SELECT * from temp_ordenesparacontrolar_conauditoria WHERE tipoafiliado  ilike 'sincontrol%' ;
 FETCH cursororden INTO rorden;
 WHILE  found LOOP
 
  respuesta = concat(respuesta,'*',rorden.nroorden,'-',rorden.centro);
   -- La dejo lista para facturar
 PERFORM expendio_cambiarestadoorden(rorden.nroorden, rorden.centro, 9);


FETCH cursororden INTO rorden;
END LOOP;
CLOSE cursororden;
END IF;

return respuesta; 
END;
$function$
