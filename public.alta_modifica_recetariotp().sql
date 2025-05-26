CREATE OR REPLACE FUNCTION public.alta_modifica_recetariotp()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;
  elidrecetarioitem BIGINT;
  lacantidadauditada INTEGER;
--CURSORES
  cursoritem CURSOR FOR SELECT * FROM  recetariotp_temporal;

--RECORD
  elem RECORD;
  rsevendiorti RECORD;
  rrtpi RECORD;
  restavinculado RECORD;
  regvinculado RECORD;
  regestaentp RECORD;
BEGIN
respuesta = true;
  SELECT INTO elem *  FROM  recetariotp_temporal;   
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
  END IF;     
  PERFORM far_abm_validacion();   

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
               IF (nullvalue(elem.idrecetariotpitem)) THEN /*No existe el item entonces lo inserto*/
                     INSERT INTO recetariotpitem(nrorecetario, centro, mnroregistro,
                            rtpipcobertura, rtpicantidadauditada,idrecetarioitempadre,idcentrorecetariotpitempadre
                             ,idvalidacionitem,idcentrovalidacionitem) 
                     VALUES (elem.nrorecetario,elem.centro,elem.mnroregistro, elem.rtpipcobertura ,elem.rtpicantidad
                                           , elem.idrecetariotpitempadre ,elem.idcentrorecetariotpitempadre
                               , elem.idvalidacionitem ,elem.idcentrovalidacionitem);   
            

               ELSE /*Existe y lo modifico*/
                   lacantidadauditada= elem.rtpicantidad;
                   IF (elem.vincular) THEN /*busco cantidades vendidas */                       
                       SELECT INTO lacantidadauditada * FROM 
                       far_cantconsumida_rtpi_v1(elem.idrecetariotpitem,elem.idcentrorecetariotpitem) as cantconsumida;
                                      
                   END IF;

                   UPDATE recetariotpitem SET rtpicantidadauditada= lacantidadauditada, rtpipcobertura=elem.rtpipcobertura
                    ,mnroregistro= elem.mnroregistro
                    ,rtpipcobertura = elem.rtpipcobertura
                    ,idvalidacionitem= elem.idvalidacionitem ,idcentrovalidacionitem=elem.idcentrovalidacionitem
                   WHERE idrecetariotpitem= elem.idrecetariotpitem AND idcentrorecetariotpitem=elem.idcentrorecetariotpitem;
               END IF;               
           ELSE 
             IF (elem.rtptaccion ILIKE '%eliminar%') THEN 
                 SELECT INTO rsevendiorti * FROM recetariotpitemuso 
                 WHERE idrecetariotpitem= elem.idrecetariotpitem AND idcentrorecetariotpitem=elem.idcentrorecetariotpitem;
                 IF NOT FOUND THEN  /*el medicamento no se vendio*/
                     SELECT INTO restavinculado * FROM recetariotpitem
                     WHERE idrecetarioitempadre= elem.idrecetariotpitem AND  
                     idcentrorecetariotpitempadre=elem.idcentrorecetariotpitem;
                     IF NOT FOUND THEN/*NO se vinculo a ningun otro medicamento*/
                          DELETE FROM recetariotpitem 
                          WHERE idrecetariotpitem= elem.idrecetariotpitem AND 
                          idcentrorecetariotpitem=elem.idcentrorecetariotpitem;
                        IF not nullvalue(elem.idvalidacion) THEN 
                          DELETE FROM  far_validacionitems 
                          WHERE idvalidacionitem= elem.idvalidacionitem AND  
                           idcentrovalidacionitem=elem.idcentrovalidacionitem;
                        END IF;
                     ELSE 
                          RAISE EXCEPTION 'No es posible eliminar el medicamento pues esta vinculado a otro medicamento!! '; 
                     END IF;
                 ELSE 
                  RAISE EXCEPTION 'No es posible eliminar el medicamento porque se ha realizado una venta del mismo!! '; 
                 END IF;
             END IF;
           END IF;
     
FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;
return respuesta;
END;$function$
