CREATE OR REPLACE FUNCTION public.cambiar_estado_recetariotp()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;

--RECORD
   rrtpestado RECORD;
   elestado RECORD;
   rrtpiu RECORD;
BEGIN
respuesta = true;      

SELECT INTO rrtpiu * FROM ttt_recetariotp LIMIT 1;  

	SELECT INTO rrtpestado *
	FROM recetariotp as r NATURAL JOIN recetariotpitem AS rtpi 				
	JOIN (SELECT  far_cantconsumida_rtpi_v1(idrecetariotpitem,idcentrorecetariotpitem) as cantconsumida,
			r.idrecetariotpitem,r.idcentrorecetariotpitem			
		   FROM recetariotpitem as r 
		   WHERE  r.nrorecetario =rrtpiu.nrorecetario AND r.centro=rrtpiu.centro) AS fcc 
	USING(idrecetariotpitem,idcentrorecetariotpitem) 	
	
	WHERE r.nrorecetario =rrtpiu.nrorecetario AND r.centro=rrtpiu.centro 
	AND rtpicantidadauditada=cantconsumida;


        IF FOUND THEN 
		INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
		VALUES(CURRENT_DATE, 5, 'Ingresado desde SP  cambiar_estado_recetariotp', rrtpiu.nrorecetario, rrtpiu.centro);
	ELSE 
           SELECT INTO elestado * FROM recetarioestados
                                  WHERE nrorecetario=rrtpiu.nrorecetario AND centro=rrtpiu.centro AND NULLVALUE(refechafin);
           IF elestado.idtipocambioestado=5 THEN -- EL RECETARIO ESTA EN ESTADO Pendiente Liquidacion PORQUE SE VENDIERON TODAS LAS CANTIDADES AUDITADAS
		INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
		VALUES(CURRENT_DATE, 4, 'Ingresado desde SP  cambiar_estado_recetariotp', rrtpiu.nrorecetario, rrtpiu.centro);
          END IF; 
        END IF; 
                  

return respuesta;
END;$function$
