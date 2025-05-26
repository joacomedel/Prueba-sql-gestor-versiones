CREATE OR REPLACE FUNCTION public.alta_modifica_segumiento_medicamento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  
  cursorfmiri CURSOR FOR SELECT * FROM  tempsegmedicamentos;
  elem RECORD;
  raux record;
 
BEGIN

respuesta = true;

open cursorfmiri;
FETCH cursorfmiri INTO elem;
WHILE FOUND LOOP

IF not nullvalue(elem.eliminar) AND elem.eliminar THEN  
-- Hay que eliminar el info

 DELETE FROM  fichamedicainfomedrecetarioitem
 WHERE idfichamedicainfomedrecetarioitem = elem.idfichamedicainfomedrecetarioitem 
 AND idcentrofichamedicainfomedrecetarioitem = elem.idcentrofichamedicainfomedrecetarioitem;
              

ELSE 
 
     IF (nullvalue(elem.idfichamedicainfomedrecetarioitem)
        ) THEN /*No existe el item O HAY que replicarlo entonces lo inserto*/
             
	INSERT INTO fichamedicainfomedrecetarioitem (nrorecetario,centro,idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento
			,idprestadorprescribe,fmimriauditor,fmimrifechavto,fmimricantidadaprobada) VALUES
		(elem.nrorecetario,elem.centro,elem.idfichamedicainfomedicamento,elem.idcentrofichamedicainfomedicamento
		,elem.idprestadorprescribe,elem.fmimriauditor,elem.fmimrifechavto,elem.fmimricantidadaprobada);

 
      ELSE

          UPDATE fichamedicainfomedrecetarioitem SET fmimrifechavto=elem.fmimrifechavto,
                   fmimricantidadaprobada= elem.fmimricantidadaprobada
                   WHERE idfichamedicainfomedrecetarioitem = elem.idfichamedicainfomedrecetarioitem
                   AND idcentrofichamedicainfomedrecetarioitem = elem.idcentrofichamedicainfomedrecetarioitem;

         

      END IF;

     


END IF;

FETCH cursorfmiri INTO elem;
END LOOP;
CLOSE cursorfmiri;


return respuesta;
END;
$function$
