CREATE OR REPLACE FUNCTION public.insertarrecetarioautomatico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
rec RECORD;
BEGIN
SELECT INTO rec * FROM recetario WHERE nrorecetario = new.nroorden  AND centro = new.centro;
IF NOT FOUND THEN 
  INSERT INTO recetario (nrorecetario,centro,fechaemision,idplancovertura,asi,gratuito)
  (SELECT orden.nroorden
       ,orden.centro
       ,orden.fechaemision
       ,ordconsulta.idplancovertura
       ,FALSE
       ,FALSE
       FROM orden
       NATURAL JOIN ordconsulta
       WHERE orden.nroorden = new.nroorden AND orden.centro = new.centro
       );
       INSERT INTO recetarioestados(idtipocambioestado,nrorecetario,centro,refechamodificacion,redescripcion)
       (SELECT 1
               ,orden.nroorden
               ,orden.centro
               ,orden.fechaemision
               ,'Insertado usando el triggers insertarrecetarioautomatico'
       FROM orden
       NATURAL JOIN ordconsulta
       WHERE orden.nroorden = new.nroorden AND orden.centro = new.centro
      );
    --inserto tambien en la nueva tabla donde se guarda la relacion entre orden y recetario
    INSERT INTO ordenrelacion(nroorden,centro,nroordenor,centroor)
       (SELECT orden.nroorden
               ,orden.centro
               ,orden.nroorden
               ,orden.centro
               
       FROM orden
       NATURAL JOIN ordconsulta
       WHERE orden.nroorden = new.nroorden AND orden.centro = new.centro
      );

END IF;
  RETURN NULL;
END;
$function$
