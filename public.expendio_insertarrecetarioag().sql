CREATE OR REPLACE FUNCTION public.expendio_insertarrecetarioag()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
  rec RECORD;
--VARIABLES
  respuesta BOOLEAN;
BEGIN

SELECT INTO rec * 
FROM ttordenesgeneradas WHERE (nroorden,centro)  IN
(SELECT  nrorecetario as nroorden, centro FROM recetario);


IF NOT FOUND THEN 
      INSERT INTO recetario (nrorecetario,centro,fechaemision,idplancovertura,asi,gratuito)
       (SELECT orden.nroorden,orden.centro,orden.fechaemision,itemvalorizada.idplancovertura
       ,FALSE,FALSE
       FROM orden NATURAL JOIN ttordenesgeneradas NATURAL JOIN itemvalorizada);

       INSERT INTO recetarioestados(idtipocambioestado,nrorecetario,centro,refechamodificacion,redescripcion)
       (SELECT 1,orden.nroorden,orden.centro,orden.fechaemision
               ,'Insertado usando FUNCTION expendio_insertarrecetarioag'
       FROM orden NATURAL JOIN ttordenesgeneradas );
    --inserto tambien en la nueva tabla donde se guarda la relacion entre orden y recetario
    INSERT INTO ordenrelacion(nroorden,centro,nroordenor,centroor)
       (SELECT orden.nroorden
               ,orden.centro
               ,orden.nroorden
               ,orden.centro
               
       FROM orden NATURAL JOIN ttordenesgeneradas 
     
      );
      respuesta = true;
END IF;
  RETURN respuesta;
END;
$function$
