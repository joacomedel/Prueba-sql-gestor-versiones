CREATE OR REPLACE FUNCTION public.alta_modifica_auditoria_medica()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  porreintegro BOOLEAN;
  cursoritem CURSOR FOR SELECT * FROM  alta_modifica_ficha_medica;
  elem RECORD;
  verifica RECORD;
  idtipopres INTEGER;
  verireintegro RECORD;
 
BEGIN

open cursoritem;
FETCH cursoritem INTO elem;
WHILE FOUND LOOP

  
  porreintegro = not nullvalue(elem.nroreintegro);
  
  IF (elem.emision = 'orden') THEN
     IF(elem.idauditoriatipo = 1) THEN 
         elem.idauditoriatipo = 2; -- Auditoria Tipo Odontología orden
     ELSE 
         elem.idauditoriatipo = 4; -- Auditoria Tipo Psicoterapia Orden
     END IF;
  END IF;
  

  
IF nullvalue(elem.idfichamedicaitem) THEN  -- Se trata de una nueva auditoria

   INSERT INTO fichamedicaitem(fmifechaauditoria,idprestador,idusuario,fmiporreintegro,fmicantidad,fmidescripcion
            ,idfichamedica,idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica) VALUES(
            elem.fmifechaauditoria,elem.idprestador,elem.idusuario,porreintegro,elem.fmicantidad,elem.fmidescripcion,elem.idfichamedica
            ,elem.idcentrofichamedica,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica);

   elem.idfichamedicaitem = currval('public.fichamedicaitem_idfichamedicaitem_seq');
   elem.idcentrofichamedicaitem = centro();


                IF (elem.idauditoriatipo = 1) OR (elem.idauditoriatipo = 2) THEN -- Se trata de una auditoria de odonto
                 INSERT INTO fichamedicaitemodonto (idpiezadental,idletradental,idfichamedicaitem,idcentrofichamedicaitem,idzonadental)
      VALUES(elem.idpiezadental,elem.idletradental,elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.idzonadental);
              ELSE -- Se trata de una ficha de Psicoterapia
                  INSERT INTO fichamedicaitemsico (iddiagnostico,idfichamedicaitem,idcentrofichamedicaitem)
        VALUES(elem.fmidiagnostico,elem.idfichamedicaitem,elem.idcentrofichamedicaitem);
             END IF;




ELSE -- Se trata de la modificacion de un item de auditoria

     UPDATE fichamedicaitem SET  fmifechaauditoria = elem.fmifechaauditoria
            ,idprestador = elem.idprestador
            ,idusuario = elem.idusuario
            ,fmiporreintegro = porreintegro
            ,fmicantidad = elem.fmicantidad
            ,fmidescripcion = elem.fmidescripcion
            ,idnomenclador = elem.idnomenclador
            ,idcapitulo = elem.idcapitulo
            ,idsubcapitulo = elem.idsubcapitulo
            ,idpractica = elem.idpractica
     WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
           
    
             UPDATE fichamedicaitemodonto SET idpiezadental = elem.idpiezadental
            ,idletradental = elem.idletradental
            ,idzonadental = elem.idzonadental
            WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
   
            UPDATE fichamedicaitemsico SET iddiagnostico = elem.fmidiagnostico
            WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
    
 /* Modifica la emision pendiente*/
     UPDATE fichamedicaemision
                        SET
                        --nrodoc = elem.nrodoc
                        --,tipodoc = elem.tipodoc
                        fmepfecha = elem.fmifechaauditoria -- MaLaPi 27-04-2018 Le coloco la fecha de auditoria, pues es lo que se ve en la interface. Ademas ahora hace falta pues se verifica para verificar la cantidad pendiente.
                      --  ,idauditoriatipo = elem.idauditoriatipo
                        ,fmepcantidad = elem.fmicantidad
                        ,idnomenclador = elem.idnomenclador
                        ,idcapitulo = elem.idcapitulo
                        ,idsubcapitulo = elem.idsubcapitulo
                        ,idpractica = elem.idpractica
                        ,tipoprestacion = idtipopres
                WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
           
END IF;

IF not nullvalue(elem.emision) AND elem.emision <> 'sinpendiente' THEN
       -- Hay que modificar o crear una emision, puede ser reintegro o una orden
       --Arreglar el reintegro para que quede consistente
       IF (elem.idauditoriatipo = 1) OR (elem.idauditoriatipo = 2) THEN
                 -- Tipo Odontologia o Psicoterapia segun corresponda
                idtipopres = 6;
       ELSE
           idtipopres = 7;
       END IF;
        
       SELECT INTO verifica * FROM fichamedicaemision WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
       IF NOT FOUND THEN
                -- MaLaPi 27-04-2018 La fecha de las emisiones ya no es mas now(), ahora es la fecha de auditoria que se ingresa en la ventana.
                INSERT INTO fichamedicaemision(nrodoc,tipodoc,fmepfecha,idauditoriatipo,idfichamedicaitem
                ,idcentrofichamedicaitem,fmepcantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,tipoprestacion,fmefechavto)
                VALUES(elem.nrodoc,elem.tipodoc,elem.fmifechaauditoria,elem.idauditoriatipo,elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.fmicantidad,elem.idnomenclador
                ,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,idtipopres,(date_trunc('YEAR', CURRENT_DATE) + INTERVAL '1 YEAR - 1 day')::DATE);
           
         END IF;
   
         UPDATE fichamedicaemisionestado SET fmeefechafin = now() WHERE idfichamedicaitem= elem.idfichamedicaitem
                                                             AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
         INSERT INTO fichamedicaemisionestado(idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaemisionestadotipo,fmeedescripcion,idauditoriatipo)
                VALUES (elem.idfichamedicaitem,elem.idcentrofichamedicaitem,1,'Generado desde Auditoria Medica',elem.idauditoriatipo);
 
 
         IF NOT nullvalue(elem.nroreintegro) THEN
                -- La emision adicional es un reintegro, hay que actualizarlo
                 SELECT INTO verifica * FROM fichamedicaitememisiones
                  WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
                 IF FOUND THEN
                          UPDATE fichamedicaitememisiones SET  nroreintegro = elem.nroreintegro
                                , anio = elem.anio
                                , idcentroregional = elem.idcentroregional
                                , fmieimporte = elem.importe
                          WHERE idfichamedicaitem = elem.idfichamedicaitem AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
   
                 ELSE
                          INSERT INTO fichamedicaitememisiones (idfichamedicaitem,idcentrofichamedicaitem,nroreintegro,anio,idcentroregional,fmieimporte,nroorden,centro)
                          VALUES (elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.nroreintegro,elem.anio,elem.idcentroregional,elem.importe,null,null);
 
                 END IF;
     
                 /*Antes de modificar el reintegro, hay que verificar que el reintegro no esta en estado Posterior a Liquidable*/
                 SELECT INTO verireintegro * FROM restados
                                 WHERE nroreintegro = elem.nroreintegro 
                                                   AND anio = elem.anio 
                                                   AND idcentroregional = elem.idcentroregional
                                                   AND restados.tipoestadoreintegro > 2;
                 IF NOT FOUND THEN
                                  UPDATE reintegroprestacion SET observacion = elem.idprestador,prestacion = elem.consumo,importe = ( SELECT sum(fmieimporte) as importe
                                               FROM  fichamedicaitememisiones
                                               WHERE fichamedicaitememisiones.nroreintegro = elem.nroreintegro
                                               AND fichamedicaitememisiones.anio = elem.anio
                                               AND fichamedicaitememisiones.idcentroregional = elem.idcentroregional
                                               AND fichamedicaitememisiones.nroreintegro = reintegroprestacion.nroreintegro
                                               AND fichamedicaitememisiones.idcentroregional = reintegroprestacion.idcentroregional
                                               AND fichamedicaitememisiones.anio = reintegroprestacion.anio)
                                  WHERE  reintegroprestacion.nroreintegro = elem.nroreintegro AND reintegroprestacion.anio = elem.anio
                                         AND reintegroprestacion.idcentroregional = elem.idcentroregional AND reintegroprestacion.tipoprestacion = idtipopres;
    
                                   UPDATE reintegro SET  rimporte = ( SELECT sum(importe) as reintegroimporte
                                          FROM reintegroprestacion
                                          WHERE reintegroprestacion.nroreintegro = elem.nroreintegro
                                           AND reintegroprestacion.anio = elem.anio
                                           AND reintegroprestacion.idcentroregional = elem.idcentroregional
                                           AND reintegroprestacion.nroreintegro = reintegro.nroreintegro
                                           AND reintegroprestacion.idcentroregional = reintegro.idcentroregional
                                           AND reintegroprestacion.anio = reintegro.anio)
                                           WHERE reintegro.nroreintegro = elem.nroreintegro AND reintegro.anio = elem.anio AND reintegro.idcentroregional = elem.idcentroregional;

                                  INSERT INTO restados(fechacambio,nroreintegro,anio,idcentroregional,tipoestadoreintegro,observacion)
                                         VALUES (now(),elem.nroreintegro,elem.anio,elem.idcentroregional,1,'Generado desde Auditoria Medica');
       
                                   IF(elem.importe <> null AND elem.importe <> 0 ) THEN
                                                   --Queda en estado 2 - Liquidable
                                                   INSERT INTO restados(fechacambio,nroreintegro,anio,idcentroregional,tipoestadoreintegro,observacion)
                                                   VALUES (now(),elem.nroreintegro,elem.anio,elem.idcentroregional,2,'Generado desde Auditoria Medica');
                                   END IF;
 
               END IF; -- Fin de se emite un reintegro
        END IF; -- Fin de Verifico que el reintegro no este en estado mayor a Liquidable
END IF; -- Fin de hay que emitir algo

IF elem.emisionadicional THEN -- Ademas de la emision, hay otra adicional
 IF elem.emision = 'orden' THEN -- El adicional es un reintegro
  IF (elem.idauditoriatipo = 1) OR (elem.idauditoriatipo = 2) THEN
     -- Tipo Odontologia o Psicoterapia segun corresponda
        idtipopres = 6;
     ELSE
        idtipopres = 7;
     END IF;
   

     INSERT INTO reintegro (anio,idcentroregional,tipodoc,nrodoc,rfechaingreso,rimporte)
     VALUES (extract('year' FROM current_date),centro(),elem.tipodoc,elem.nrodoc,current_date,elem.importe);
     elem.nroreintegro = currval('reintegro_nroreintegro_seq');
     elem.anio = extract('year' FROM current_date);
     elem.idcentroregional = centro();
     INSERT INTO reintegroprestacion(anio,nroreintegro,tipoprestacion,importe,observacion,prestacion,cantidad,idcentroregional)
     VALUES (elem.anio,elem.nroreintegro,idtipopres,elem.importe,elem.idprestador,elem.consumo,elem.fmicantidad,elem.idcentroregional);

     SELECT INTO verifica * FROM fichamedicaitememisiones 
                 WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
     IF FOUND THEN
        UPDATE fichamedicaitememisiones SET  nroreintegro = elem.nroreintegro
                                , anio = elem.anio
                                , idcentroregional = elem.idcentroregional
                                , fmieimporte = elem.importe
        WHERE idfichamedicaitem = elem.idfichamedicaitem AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
   
     ELSE
        INSERT INTO fichamedicaitememisiones (idfichamedicaitem,idcentrofichamedicaitem,nroreintegro,anio,idcentroregional,fmieimporte,nroorden,centro)
               VALUES (elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.nroreintegro,elem.anio,elem.idcentroregional,elem.importe,null,null);       
 
     END IF;
 ELSE -- El adicional es una Orden
 IF  (elem.idauditoriatipo = 3) OR (elem.idauditoriatipo = 4)  THEN -- Se trata de la auditoria de Psicoterapia
    elem.idauditoriatipo = 4; -- Para que genere un pendiente para Orden
 END IF;
 IF  (elem.idauditoriatipo = 1) OR (elem.idauditoriatipo = 2) THEN -- Se trata de la auditoria de Odontologia
    elem.idauditoriatipo = 2; -- Para que genere un pendiente para Orden
 END IF;
 
 SELECT INTO verifica * FROM fichamedicaemision WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
   IF FOUND THEN
        -- MaLaPi 27-04-2018 La fecha de las emisiones ya no es mas now(), ahora es la fecha de auditoria que se ingresa en la ventana.
      UPDATE fichamedicaemision
                 SET nrodoc = elem.nrodoc
                ,tipodoc = elem.tipodoc
                ,fmepfecha = elem.fmifechaauditoria
                ,idauditoriatipo = elem.idauditoriatipo
                ,fmepcantidad = elem.fmicantidad
                ,idnomenclador = elem.idnomenclador
                ,idcapitulo = elem.idcapitulo
                ,idsubcapitulo = elem.idsubcapitulo
                ,idpractica = elem.idpractica
                ,tipoprestacion = idtipopres
                ,fmefechavto = (date_trunc('YEAR', CURRENT_DATE) + INTERVAL '1 YEAR - 1 day')::DATE
      WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
    ELSE
      -- MaLaPi 27-04-2018 La fecha de las emisiones ya no es mas now(), ahora es la fecha de auditoria que se ingresa en la ventana.         
      INSERT INTO fichamedicaemision(nrodoc,tipodoc,fmepfecha,idauditoriatipo,idfichamedicaitem
      ,idcentrofichamedicaitem,fmepcantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,tipoprestacion,fmefechavto)
       VALUES(elem.nrodoc,elem.tipodoc,elem.fmifechaauditoria,elem.idauditoriatipo,elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.fmicantidad,elem.idnomenclador
       ,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,idtipopres,(date_trunc('YEAR', CURRENT_DATE) + INTERVAL '1 YEAR - 1 day')::DATE);
           
    END IF;
   
    UPDATE fichamedicaemisionestado SET fmeefechafin = now() WHERE idfichamedicaitem= elem.idfichamedicaitem
                                                             AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
    INSERT INTO fichamedicaemisionestado(idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaemisionestadotipo,fmeedescripcion,idauditoriatipo)
    VALUES (elem.idfichamedicaitem,elem.idcentrofichamedicaitem,1,'Generado desde Auditoria Medica',elem.idauditoriatipo);
 
    

 END IF; -- Fin de El adicional es un reintegro
END IF; --Fin de emision adicional

-- Elimino el pendiente de turno
 DELETE FROM fichamedicaitempendiente  WHERE nrodoc = elem.nrodoc
                                        AND tipodoc =elem.tipodoc
                                        /*AND idauditoriatipo = elem.idauditoriatipo*/;

FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;


return respuesta;
END;
$function$
