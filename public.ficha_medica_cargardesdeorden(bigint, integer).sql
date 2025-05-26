CREATE OR REPLACE FUNCTION public.ficha_medica_cargardesdeorden(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN; 
  elidfichamedicaitem INTEGER;
 
--RECORD
  rfichamedica RECORD;
  rusuario RECORD; 
 

BEGIN

respuesta = true;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 IF NOT FOUND THEN 
        rusuario.idusuario = 25;
 END IF;

SELECT INTO rfichamedica fechaemision as fmifechaauditoria, idprestador, idusuario, false as fmiporreintegro, item.cantidad as fmpacantidad, null as fmpadescripcion, idfichamedica, idcentrofichamedica,
 idnomenclador, idcapitulo,idsubcapitulo,idpractica
FROM (SELECT max(prioridadconfodonto) as prioridadconfodonto,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion,iditem, centro
                FROM item  
                NATURAL JOIN itemvalorizada
                NATURAL JOIN ordvalorizada 
                NATURAL JOIN practicasodontograma 
                NATURAL JOIN consumo  
               WHERE idnomenclador='14' AND nroorden= $1 AND centro=$2 AND not anulado
               GROUP BY iditem, centro,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion
           ) as  item
        NATURAL JOIN practicasodontograma  as po
        NATURAL JOIN itemvalorizada
        NATURAL JOIN orden  
	NATURAL JOIN ordenrecibo 
	NATURAL JOIN recibousuario
        NATURAL JOIN persona   
        NATURAL JOIN consumo
	NATURAL JOIN ordvalorizada 
	NATURAL JOIN fichamedica
        LEFT JOIN ordenodonto USING (iditem, centro,nroorden)
 	LEFT JOIN matricula ON ( CASE WHEN trim(ordvalorizada.malcance) = ''  THEN matricula.idprestador = ordvalorizada.nromatricula ELSE ordvalorizada.nromatricula = matricula.nromatricula::bigint AND ordvalorizada.malcance =matricula.malcance AND  ordvalorizada.mespecialidad = matricula.mespecialidad END) 
	LEFT JOIN prestador USING(idprestador)
        WHERE nroorden= $1 AND centro=$2 AND idauditoriatipo=2;
	--WHERE nroorden= 970144 AND centro=1 AND idauditoriatipo=2;


IF FOUND THEN 
        INSERT INTO fichamedicaitem (fmifechaauditoria,idprestador,idusuario,fmiporreintegro,fmicantidad,fmidescripcion
            ,idfichamedica,idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idcentrofichamedicaitem)  
        VALUES(rfichamedica.fmifechaauditoria, rfichamedica.idprestador, rfichamedica.idusuario, rfichamedica.fmiporreintegro, rfichamedica.fmpacantidad, rfichamedica.fmpadescripcion, rfichamedica.idfichamedica, rfichamedica.idcentrofichamedica, rfichamedica.idnomenclador, rfichamedica.idcapitulo, rfichamedica.idsubcapitulo, rfichamedica.idpractica,$2);

      elidfichamedicaitem = currval('public.fichamedicaitem_idfichamedicaitem_seq');
     
      INSERT INTO fichamedicaitemestado(idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaemisionestadotipo,fmiedescripcion,fmieusuario)
                VALUES (elidfichamedicaitem,$2,3,'Generado desde ficha_medica_cargardesdeorden',rusuario.idusuario);
 
      
      INSERT INTO fichamedicaitemodonto (idpiezadental,idletradental,idfichamedicaitem,idcentrofichamedicaitem,idzonadental)
      
      SELECT idpiezadental, idletradental, elidfichamedicaitem, $2, idzonadental  
  	FROM (SELECT max(prioridadconfodonto) as prioridadconfodonto,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion,iditem, centro
                FROM item  
                NATURAL JOIN itemvalorizada
                NATURAL JOIN ordvalorizada 
                NATURAL JOIN practicasodontograma 
                NATURAL JOIN consumo  
               WHERE idnomenclador='14' AND nroorden= $1 AND centro=$2 AND not anulado
               GROUP BY iditem, centro,cantidad,idnomenclador, idcapitulo,idsubcapitulo,idpractica,pdescripcion
           ) as  item
        NATURAL JOIN practicasodontograma  as po
        NATURAL JOIN itemvalorizada
        NATURAL JOIN orden  
        LEFT JOIN ordenodonto USING (iditem, centro,nroorden)
	WHERE nroorden= $1 AND centro=$2;

        INSERT INTO fichamedicaitememisiones (idfichamedicaitem,idcentrofichamedicaitem,nroorden,centro)
                          VALUES (elidfichamedicaitem, $2,$1,$2);
 


END IF; 

--KR 27-06-19  Genero el pendiente de auditoria de las ordenes online que requieren auditoria
--PERFORM w_ficha_medica_cargardesdeordenonline(concat('{"nroorden":' $1,',', '"centro":', $2,'}')::jsonb);


 
return respuesta;
END;
$function$
