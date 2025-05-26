CREATE OR REPLACE FUNCTION public.venta_recetariotp()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;

--CURSORES
  cursoritem CURSOR FOR SELECT * FROM  temp_recetariotpitemuso;

--RECORD
  elem RECORD;
  rrtpestado RECORD;
  rrtpiu RECORD;
  rtpie RECORD;
 
BEGIN
respuesta = true;
 SELECT INTO rrtpiu *  FROM  temp_recetariotpitemuso;   
OPEN cursoritem;
FETCH cursoritem INTO elem;  
              
         
  WHILE FOUND LOOP
	INSERT INTO recetariotpitemuso (idrecetariotpitem,idcentrorecetariotpitem,rtpiufechauso, 
					idordenventa, idcentroordenventa) 
	VALUES (elem.idrecetariotpitem,elem.idcentrorecetariotpitem,now(),
		elem.idordenventa,elem.idcentroordenventa);
	
     
--analizo si se vendió todo la cantidad aprobada del item del recetario 

        SELECT INTO rtpie *
          FROM recetariotpitem 
          WHERE rtpicantidadauditada = far_cantconsumida_rtpi_v1(elem.idrecetariotpitem, elem.idcentrorecetariotpitem)
                   AND nrorecetario=rrtpiu.nrorecetario AND centro=rrtpiu.centro
                   AND idrecetariotpitem= elem.idrecetariotpitem AND idcentrorecetariotpitem=elem.idcentrorecetariotpitem;  
        IF FOUND THEN 
             PERFORM far_cambiarestadorecetarioitem(elem.idrecetariotpitem, elem.idcentrorecetariotpitem, 5, 'Se vendio toda la cantidad auditada. ');

        END IF;

 END LOOP;

  
       PERFORM  cambiar_estado_recetariotp(rrtpiu.nrorecetario::integer,rrtpiu.centro);

       
CLOSE cursoritem;
return respuesta;
END;$function$
