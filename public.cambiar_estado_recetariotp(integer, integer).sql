CREATE OR REPLACE FUNCTION public.cambiar_estado_recetariotp(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;

--RECORD
   rrtpestado RECORD;
   elestado RECORD;
   
BEGIN
respuesta = true;      



	SELECT INTO rrtpestado *
	FROM recetariotp as r NATURAL JOIN recetariotpitem AS rtpi 				
	JOIN (SELECT  far_cantconsumida_rtpi_v1(idrecetariotpitem,idcentrorecetariotpitem) as cantconsumida,
			r.idrecetariotpitem,r.idcentrorecetariotpitem			
		   FROM recetariotpitem as r 
		   WHERE  r.nrorecetario =$1 AND r.centro=$2) AS fcc 
	USING(idrecetariotpitem,idcentrorecetariotpitem) 	
	
	WHERE r.nrorecetario =$1 AND r.centro=$2
	AND rtpicantidadauditada=cantconsumida;


        IF FOUND THEN 
		INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
		VALUES(CURRENT_DATE, 5, 'Ingresado desde SP  cambiar_estado_recetariotp', $1, $2);
	ELSE 
           SELECT INTO elestado * FROM recetarioestados
                                  WHERE nrorecetario= $1 AND centro=$2 AND NULLVALUE(refechafin);
           IF elestado.idtipocambioestado=5 THEN -- EL RECETARIO ESTA EN ESTADO Pendiente Liquidacion PORQUE SE VENDIERON TODAS LAS CANTIDADES AUDITADAS
		INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
		VALUES(CURRENT_DATE, 4, 'Ingresado desde SP  cambiar_estado_recetariotp',  $1, $2);
          END IF; 
        END IF; 
                  

return respuesta;
END;$function$
