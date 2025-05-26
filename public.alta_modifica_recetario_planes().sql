CREATE OR REPLACE FUNCTION public.alta_modifica_recetario_planes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;
  elidrecetarioitem BIGINT;
  lacantidadauditada INTEGER;
  cantconsumida INTEGER;
--CURSORES
  cursoritem CURSOR FOR SELECT * FROM  recetariotp_temporal  LEFT JOIN fichamedicainfomedicamento USING(idfichamedicainfomedicamento, idcentrofichamedicainfomedicamento);

--RECORD
  elem RECORD;
  rsevendiorti RECORD;
  rrtpi RECORD;
  restavinculado RECORD;
  regvinculado RECORD;
  regestaentp RECORD;
  rexisterece RECORD;
  relitemrece RECORD;
BEGIN
respuesta = true;
  SELECT INTO elem *  FROM  recetariotp_temporal; 

  SELECT INTO rexisterece * FROM  recetariotp  
        WHERE nrorecetario= elem.nrorecetario  AND centro=elem.centro;
  IF NOT FOUND THEN 
       INSERT INTO recetariotp (nrorecetario,centro)  VALUES(elem.nrorecetario, elem.centro);
       rexisterece.idvalidacion = NULL;
  END IF;
  IF NOT nullvalue(rexisterece.idvalidacion) THEN 
     /*se modifica el recetario*/   
       UPDATE recetariotp_temporal SET idvalidacion = rexisterece.idvalidacion                                
                                          ,idcentrovalidacion= rexisterece.idcentrovalidacion; 
  ELSE /*SE da de alta el recetario*/  
          INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
             VALUES(CURRENT_DATE, 4, 'Ingresado desde SP alta_modifica_recetariotp', elem.nrorecetario, elem.centro);
  END IF; 
  PERFORM far_abm_validacion();   
     

   UPDATE recetariotp SET idusuario = elem.idusuario, rtpfechavto = elem.rtpfechavto
                  ,rtpfechaauditoria= elem.rtpfechaauditoria
                  ,idvalidacion =  elem.idvalidacion ,idcentrovalidacion= elem.idcentrovalidacion
                  ,nromatricula= elem.nromatricula,malcance= elem.malcance,mespecialidad= elem.mespecialidad
         WHERE  centro =elem.centro and nrorecetario = elem.nrorecetario;

OPEN cursoritem;
FETCH cursoritem INTO elem;         
WHILE FOUND LOOP
     
        SELECT   INTO relitemrece * 
	FROM recetariotpitem AS rtpi NATURAL JOIN medicamento NATURAL JOIN manextra 
JOIN recetarioitemestado AS rtpie ON (rtpi.idrecetariotpitem=rtpie.idrecetarioitem AND rtpi.idcentrorecetariotpitem=rtpie.idcentrorecetarioitem and nullvalue(riefechafin))	 
	WHERE nrorecetario = elem.nrorecetario and  centro= elem.centro AND idmonodroga = elem.idmonodroga AND rtpie.idtipocambioestado=4   ;
	IF FOUND THEN --modifico un item con la misma monodroga
	
	   /*cancelo el item anterior del recetario y de la validacion */                   
                  
		   PERFORM  far_cambiarestadovalidacionitem(T.idvalidacionitemsestado,T.idcentrovalidacionitemsestado, T.idvalidacionitem, T.idcentrovalidacionitem,3) FROM (
			SELECT idvalidacionitemsestado,idcentrovalidacionitemsestado,idvalidacionitem,idcentrovalidacionitem  
			FROM far_validacionitemsestado NATURAL JOIN far_validacionitems  
			WHERE idvalidacionitem= relitemrece.idrecetariotpitem  AND  idcentrovalidacionitem=relitemrece.idcentrorecetariotpitem  AND nullvalue(viefechafin)) AS T;

                   PERFORM far_cambiarestadorecetarioitem(relitemrece.idrecetariotpitem, relitemrece.idcentrorecetariotpitem, 7, 'Se cancela el item al ser modificado el medicamento ');
	--Inserto la nueva monodroga con la cantidad elegida, menos lo que se vendió, en caso de que se vendiera algo
--KR 25-09-18 AHORA se puede modificar la cantidad desde la interface. Se controla ahi que la nueva cantidad sea superior o igual a la vendida                  
 /* SELECT INTO cantconsumida * FROM 
                       far_cantconsumida_rtpi_v1(relitemrece.idrecetariotpitem,relitemrece.idcentrorecetariotpitem) as cantconsumida;
		   elem.rtpicantidad = relitemrece.rtpicantidadauditada-cantconsumida;
*/ 
	END IF; 

         
	INSERT INTO recetariotpitem(nrorecetario, centro, mnroregistro, rtpipcobertura, rtpicantidadauditada,
               idrecetarioitempadre,idcentrorecetariotpitempadre ,idvalidacionitem,idcentrovalidacionitem) 
        VALUES (elem.nrorecetario,elem.centro,elem.mnroregistro,(elem.fmimcobertura*100)  ,elem.rtpicantidad,    	
		relitemrece.idrecetariotpitem ,relitemrece.idcentrorecetariotpitem, elem.idvalidacionitem ,elem.idcentrovalidacionitem);
	PERFORM far_cambiarestadorecetarioitem(currval('recetariotpitem_idrecetariotpitem_seq'::regclass), centro(), 4, 'Se presenta el recetario TP en farmacia. '); 
      INSERT INTO fichamedicainfomedrecetarioitem(idrecetariotpitem,idcentrorecetariotpitem,idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento, nrorecetario, centro)  VALUES (currval('recetariotpitem_idrecetariotpitem_seq'::regclass),centro(),elem.idfichamedicainfomedicamento, elem.idcentrofichamedicainfomedicamento ,elem.nrorecetario,elem.centro);
           
	    
          
     
FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;
return respuesta;
END;$function$
