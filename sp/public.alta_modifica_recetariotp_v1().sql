CREATE OR REPLACE FUNCTION public.alta_modifica_recetariotp_v1()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;
  elidrecetarioitem BIGINT;
  lacantidadauditada INTEGER;
  cantconsumida INTEGER;
--CURSORES
  cursoritem CURSOR FOR SELECT * FROM  recetariotp_temporal;

--RECORD
  elem RECORD;
  rsevendiorti RECORD;
  rrtpi RECORD;
  restavinculado RECORD;
  regvinculado RECORD;
  regestaentp RECORD;
  rexisterece RECORD;
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
     


     /*
  IF nullvalue(elem.idvalidacion) THEN /*se da de alta por primera vez el recetario*/                        
             
             SELECT INTO regvinculado * FROM fichamedicainfomedrecetarioitem  
                            WHERE nrorecetario= elem.nrorecetario  AND centro=elem.centro;
             IF FOUND THEN 

                SELECT INTO regestaentp * FROM recetariotp  
                            WHERE nrorecetario= elem.nrorecetario  AND centro=elem.centro;
                IF NOT FOUND THEN 
                 INSERT INTO recetariotp (nrorecetario,centro)  VALUES(elem.nrorecetario, elem.centro);
                END IF;
                 INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
                 VALUES(CURRENT_DATE, 6, 'Recetario Auditado Ingresado desde SP alta_modifica_recetariotp', elem.nrorecetario, elem.centro);

             ELSE
                  INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
             VALUES(CURRENT_DATE, 4, 'Ingresado desde SP alta_modifica_recetariotp', elem.nrorecetario, elem.centro);
             
             END IF; 
     PERFORM far_abm_validacion();   
  END IF;     
 */

OPEN cursoritem;
FETCH cursoritem INTO elem;  
              
          UPDATE recetariotp SET idusuario = elem.idusuario, rtpfechavto = elem.rtpfechavto
                  ,rtpfechaauditoria= elem.rtpfechaauditoria
                  ,idvalidacion =  elem.idvalidacion ,idcentrovalidacion= elem.idcentrovalidacion
                  ,nromatricula= elem.nromatricula,malcance= elem.malcance,mespecialidad= elem.mespecialidad
         WHERE  centro =elem.centro and nrorecetario = elem.nrorecetario;
     
  WHILE FOUND LOOP
    
           IF  (elem.rtptaccion ILIKE '%modificarrtp%') THEN
          /*actualizo los datos de la monodroga*/
               IF (not (nullvalue(elem.idrecetariotpitem)) or not nullvalue(elem.idrecetariotpitempadre)) THEN /*Existe el item modifico estado de item de recetario y de validacion*/                 		   
                   
                                            
--- KR 08-05 PONGO EL ITEM DEL RECETARIO EN ESTADO CANCELADO. CREE NUEVA TABLA, recetariotpitemestado FALTA PONERLA SINCRO
                 IF (elem.vincular) THEN /*cancelo el item anterior del recetario y de la validacion */                   
                 
------falta el centro en la tabla sincronizable far_validacionitemsestado (ya estaba creada )
		   PERFORM  far_cambiarestadovalidacionitem(T.idvalidacionitemsestado,T.idcentrovalidacionitemsestado, T.idvalidacionitem, T.idcentrovalidacionitem,3) FROM (
			SELECT idvalidacionitemsestado,idcentrovalidacionitemsestado,idvalidacionitem,idcentrovalidacionitem  FROM far_validacionitemsestado NATURAL JOIN far_validacionitems  NATURAL JOIN recetariotpitem
			WHERE idrecetariotpitem= elem.idrecetariotpitempadre  AND  idcentrorecetariotpitem=elem.idcentrorecetariotpitempadre AND nullvalue(viefechafin)) AS T;

                   PERFORM far_cambiarestadorecetarioitem(elem.idrecetariotpitempadre, elem.idcentrorecetariotpitempadre, 7, 'Se cancela el item al ser modificado el medicamento ');
	--Inserto la nueva monodroga con la cantidad elegida, menos lo que se vendió, en caso de que se vendiera algo
                    SELECT INTO cantconsumida * FROM 
                       far_cantconsumida_rtpi_v1(elem.idrecetariotpitempadre,elem.idcentrorecetariotpitempadre) as cantconsumida;
		   elem.rtpicantidad = elem.rtpicantidad-cantconsumida;
            
                 ELSE --no vinculo un nuevo medicamento, modifico el porcentaje de cobertura del mismo
                    
                     UPDATE recetarioitemestado SET riedescripcion =concat(riedescripcion, 'Se modifico el recetario (porcentaje de cobertura  de la monodroga o se agrego otro item) el dia ', now())
                       WHERE idrecetarioitem =elem.idrecetariotpitem AND idcentrorecetarioitem = elem.idcentrorecetariotpitem AND nullvalue(riefechafin);
                 END IF; --  IF (elem.vincular) THEN

               END IF; --IF (not (nullvalue(elem.idrecetariotpitem))) 
          END IF;--  IF  (elem.rtptaccion ILIKE '%modificarrtp%') THEN
            IF (elem.vincular OR nullvalue(elem.idrecetariotpitem)) THEN
                   INSERT INTO recetariotpitem(nrorecetario, centro, mnroregistro, rtpipcobertura, rtpicantidadauditada,
               idrecetarioitempadre,idcentrorecetariotpitempadre ,idvalidacionitem,idcentrovalidacionitem) 
               VALUES (elem.nrorecetario,elem.centro,elem.mnroregistro, elem.rtpipcobertura ,elem.rtpicantidad,    	
		elem.idrecetariotpitempadre ,elem.idcentrorecetariotpitempadre, elem.idvalidacionitem ,elem.idcentrovalidacionitem);
		   PERFORM far_cambiarestadorecetarioitem(currval('recetariotpitem_idrecetariotpitem_seq'::regclass), centro(), 4, 'Se presenta el recetario TP en farmacia. ');
                       
            END IF;--  IF (elem.vincular OR nullvalue())    
	    
          
     
FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;
return respuesta;
END;

$function$
