CREATE OR REPLACE FUNCTION public.cambiarestadoauditoriaoo(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD
rfiltros RECORD;

BEGIN

EXECUTE sys_dar_filtros(parametro) INTO rfiltros;

IF NOT  iftableexists('temp_alta_modifica_ficha_medica') THEN
    CREATE TEMP TABLE temp_alta_modifica_ficha_medica (       
				   idfichamedica integer,       
				   idcentrofichamedica integer,       
				   idfichamedicaitem integer,       
				   idcentrofichamedicaitem integer,       
				   idfichamedicaitempendiente integer,       
				   idcentrofichamedicaitempendiente integer,       
				   fmifechaauditoria date,       
				   fmicantidad integer,      
				   fmidescripcion varchar,       
				   idprestador bigint,       
				   iditem bigint,       
				   iditemestadotipo integer,     
				   idusuario integer,      
				   iicoberturasosuncsugerida float,      
				   operacion varchar,      
				   lapractica varchar,      
				   nrodoc varchar,       
				   tipodoc integer,      
				   idauditoriatipo integer,       
				   nroorden bigint,      
				   centro integer,       
				   cobertura double precision,      
				   iierror varchar      
				
				  ) ;

ELSE 
	DELETE FROM temp_alta_modifica_ficha_medica;
END IF;
/*
OPEN cursoritem FOR SELECT * from
/* SELECT CONCAT(nroorden, '-', centro) as laorden, to_char(fmpfecha, 'DD/MM/YY hh:mm:ss') as fmpfechaformato,*, extract('year' from age(fechanac))::varchar as edad, CONCAT(idfichamedica,'-',idcentrofichamedica) AS elidfichamedica, CONCAT(apellido, ', ', nombres) as elafiliado,  concat(idfichamedicaitempendiente, '-', idcentrofichamedicaitempendiente) as idfichamedicaitem, fichamedicaitempendiente.*, prestador.idprestador, prestador.pcuit, prestador.pdescripcion, concat('(',prestador.pcuit,') ', prestador.pdescripcion) as elprestador ,acdecripcion	
*/
FROM  fichamedicaitempendiente  NATURAL JOIN fichamedicaitempendienteestado NATURAL JOIN fichamedica NATURAL JOIN persona JOIN consumo ON(nroreintegro=nroorden AND idcentroregional=centro) NATURAL JOIN orden NATURAL JOIN ordvalorizada JOIN prestador ON (nromatricula = idprestador)	NATURAL JOIN asocconvenio 	

WHERE  NULLVALUE(fmipfechafin) AND idfichamedicaemisionestadotipo=1  AND idauditoriatipo = 5  AND NOT anulado AND tipo=56   	AND  not nullvalue(nroreintegro) AND true 

AND idconvenio<>261 and idasocconv<>127 AND idconvenio<>262 and idasocconv<>122

ORDER BY nroorden;

--temp_alta_modifica_ficha_medica; esta sera cuando se llame desde java
FETCH cursoritem INTO ritem;
WHILE  found LOOP

*/
INSERT INTO temp_alta_modifica_ficha_medica (iditem, operacion,iicoberturasosuncsugerida,iditemestadotipo,idfichamedica,idcentrofichamedica,  idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaitempendiente,idcentrofichamedicaitempendiente,fmifechaauditoria,fmicantidad,fmidescripcion,idprestador,idusuario,lapractica,nroorden, centro,nrodoc,tipodoc,idauditoriatipo,cobertura,iierror)        
				SELECT DISTINCT ON (iditem) iditem,'rechazar','0.0',1,idfichamedica,idcentrofichamedica,NULL,NULL,idfichamedicaitempendiente,idcentrofichamedicaitempendiente,NOW()
,1,NULL,idprestador, 25,concat(item.idnomenclador,'.', item.idcapitulo, '.', item.idsubcapitulo, '.', item.idpractica ) 

,nroorden, centro,nrodoc,tipodoc,idauditoriatipo,cobertura,'La practica NO fue autorizada. Se rechaza desde el sp cambiarestadoauditoriaoo. '

			    
FROM fichamedicaitempendiente NATURAL JOIN fichamedicaitempendienteestado NATURAL JOIN fichamedica NATURAL JOIN persona      
 JOIN ordvalorizada ON (nroreintegro=nroorden AND idcentroregional=centro) NATURAL JOIN consumo  NATURAL JOIN orden  NATURAL JOIN itemvalorizada 
 NATURAL JOIN item   LEFT JOIN prestador ON (nromatricula = idprestador) 
natural join asocconvenio

 WHERE NULLVALUE(fmipfechafin) AND idfichamedicaemisionestadotipo=1 AND idauditoriatipo = 5  and not anulado AND tipo=56

and NOT ((idconvenio=262  and idasocconv=122 ) oR    (idconvenio=261  and idasocconv=127 ))
--AND nroorden <= 1072068
--and fechaemision <='2020-02-29'
AND fechaemision::date between to_date(rfiltros.fechadesde,'YYYY-MM-DD') AND to_date(rfiltros.fechahasta,'YYYY-MM-DD')
 order by iditem;

perform alta_modifica_auditoria_vincular_orden();
/*	IF NOT FOUND THEN
		--DELETE FROM ttordenesgeneradas;
		--SELECT INTO rrecibocompleto * FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = centro(); 
		--respuestajson = row_to_json(rrecibocompleto);
		RAISE EXCEPTION 'No se encontro el recibo.(rrecibo,%)',parametro;
	 END IF;
*/

RETURN 'todook';

END;
$function$
