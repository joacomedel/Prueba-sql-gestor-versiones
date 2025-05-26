CREATE OR REPLACE FUNCTION public.elimina_preauditoria_odonto(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  cursoritem CURSOR FOR SELECT * FROM  fichamedicapreauditada_temporal;

 
  elemrecetario RECORD;
  elemriexiste RECORD;
  elem RECORD;
  rfichamedica RECORD;
  rprestador matricula%rowtype; 
  rordenesusadas RECORD;
  rorden RECORD;
  rfacturaordenesutilizadas RECORD;
  elidrecetarioitem BIGINT;
  vidfichamedicapreauditada BIGINT;
  simportepagar float;
 
BEGIN

respuesta = true;




open cursoritem;
FETCH cursoritem INTO elem;


SELECT INTO rfichamedica * FROM fichamedica
 WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc AND idauditoriatipo = elem.idauditoriatipo;
IF NOT FOUND THEN
   INSERT INTO fichamedica (nrodoc,tipodoc,fmdescripcion,idauditoriatipo)
   VALUES (elem.nrodoc,elem.tipodoc,'Generado automaticamente desde una pre auditoria',elem.idauditoriatipo);
   
   SELECT INTO rfichamedica * FROM fichamedica
   WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc AND idauditoriatipo = elem.idauditoriatipo;
   
END IF;

SELECT INTO rprestador * FROM matricula WHERE idprestador =  elem.idprestador;
   
SELECT INTO rordenesusadas * FROM ordenesutilizadas 
WHERE nroorden = elem.nroorden AND centro = elem.centro AND tipo=elem.tipo;
IF NOT FOUND THEN
    INSERT INTO ordenesutilizadas
    (nroorden,centro,idprestador,fechauso,fechaauditoria,nromatricula,malcance,mespecialidad,idplancobertura,nrodocuso,tipodocuso,tipo)
    VALUES (elem.nroorden,elem.centro,elem.idprestador,elem.fechauso,now(),rprestador.nromatricula,rprestador.malcance,rprestador.mespecialidad,elem.idplancobertura,elem.nrodoc, elem.tipodoc, elem.tipo);
    
ELSE 
    UPDATE ordenesutilizadas SET  idprestador = elem.idprestador
                                  ,fechauso = elem.fechauso
                               --   ,importe = elem.importe
                                  ,fechaauditoria = now()
                                  ,nromatricula = rprestador.nromatricula
                                  ,malcance = rprestador.malcance
                                  ,mespecialidad = rprestador.mespecialidad
                                  ,idplancobertura = elem.idplancobertura
                                  ,nrodocuso = elem.nrodoc
                                  ,tipodocuso  =  elem.tipodoc
    WHERE nroorden = elem.nroorden AND centro = elem.centro AND tipo = elem.tipo;
  
    
END IF;

  

WHILE FOUND LOOP

IF nullvalue(elem.idfichamedicapreauditada) THEN

      INSERT INTO fichamedicapreauditada
      (fmpaporeintegro,idauditoriaodontologiacodigo,idnomenclador,idcapitulo,idsubcapitulo,idpractica
      ,fmpacantidad,fmpaidusuario,fmpafechaingreso,idfichamedica,idcentrofichamedica,fmpadescripcion
      ,fmpaiimportes,fmpaiimporteiva,fmpaiimportetotal,
      fmpaimportedebito,fmpadescripciondebito,idmotivodebitofacturacion)
      VALUES(elem.fmpaporeintegro,0,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica
      ,elem.fmpacantidad,elem.fmpaidusuario,CURRENT_TIMESTAMP,rfichamedica.idfichamedica,rfichamedica.idcentrofichamedica,elem.fmpadescripcion
      ,elem.fmpaiimportes,elem.fmpaiimporteiva,elem.fmpaiimportetotal,
      elem.importedebito,elem.descripciondebito,elem.idmotivodebitofacturacion);

      vidfichamedicapreauditada = currval('fichamedicapreauditada_idfichamedicapreauditada_seq'::regclass);


     -- SELECT INTO rorden * FROM orden WHERE nroorden = elem.nroorden AND centro = elem.centro;

      IF elem.tipo = 4 THEN
        INSERT INTO fichamedicapreauditadaitemconsulta (nroorden,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingres)
        VALUES(elem.nroorden,elem.centro,vidfichamedicapreauditada,centro(),CURRENT_TIMESTAMP);
      ELSE 
        IF elem.tipo = 14 or elem.tipo= 37 THEN 


              SELECT INTO elemrecetario * FROM temprecetarioitem WHERE mnroregistro = elem.iditem AND centro = elem.centro and nrorecetario = elem.nroorden;
              INSERT INTO recetarioitem(nrorecetario, centro, mnroregistro, idmotivodebito, importe, importeapagar, ridebito
                                        , importevigente, coberturaporplan, coberturaefectiva ) 
              VALUES (elemrecetario.nrorecetario, elemrecetario.centro,elemrecetario.mnroregistro,elemrecetario.idmotivodebito
                     ,elemrecetario.importe,elemrecetario.importeapagar,elemrecetario.ridebito
                     ,elemrecetario.importevigente,elemrecetario.coberturaporplan,elemrecetario.coberturaefectiva);



           elidrecetarioitem =  currval('recetarioitem_idrecetarioitem_seq');



              INSERT INTO fichamedicapreauditadaitemrecetario 
              (idrecetarioitem,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingres)
               VALUES(elidrecetarioitem,elem.centro,vidfichamedicapreauditada,centro(),CURRENT_TIMESTAMP);
        ELSE 
               INSERT INTO fichamedicapreauditadaitem 
                (iditem,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingreso)
                VALUES(elem.iditem,elem.centro,vidfichamedicapreauditada, centro(),CURRENT_TIMESTAMP);
       
         END IF;
      END IF;
      IF elem.idauditoriatipo = 2 THEN 
          INSERT INTO fichamedicapreauditadaodonto (idpiezadental,idletradental,idzonadental,idfichamedicapreauditada,idcentrofichamedicapreauditada)
      VALUES(elem.idpiezadental,elem.idletradental,elem.idzonadental,vidfichamedicapreauditada,centro());
      END IF;

ELSE
      /*Malapi 12-10-2012 Comento la modificacion a fmpafechaingreso pues no se si es mejor que quede el dia que se cargo inicialmente o la ultima vez que se toco*/
      UPDATE fichamedicapreauditada SET fmpaporeintegro= elem.fmpaporeintegro
                                    ,idauditoriaodontologiacodigo=elem.idauditoriaodontologiacodigo
                                    ,idnomenclador=elem.idnomenclador
                                    ,idcapitulo=elem.idcapitulo
                                    ,idsubcapitulo= elem.idsubcapitulo
                                    ,idpractica= elem.idpractica
                                    ,fmpacantidad= elem.fmpacantidad
                                    ,fmpaidusuario= elem.fmpaidusuario
                                   -- ,fmpafechaingreso= elem.fmpafechaingreso
                                    ,idfichamedica= rfichamedica.idfichamedica
                                    ,idcentrofichamedica= rfichamedica.idcentrofichamedica
                                    ,fmpadescripcion = elem.fmpadescripcion
                                    ,fmpaiimportes = elem.fmpaiimportes
                                    ,fmpaiimporteiva = elem.fmpaiimporteiva
                                    ,fmpaiimportetotal = elem.fmpaiimportetotal
                                    ,idmotivodebitofacturacion = elem.idmotivodebitofacturacion
                                    ,fmpaimportedebito = elem.importedebito
                                    ,fmpadescripciondebito = elem.descripciondebito
      WHERE idfichamedicapreauditada = elem.idfichamedicapreauditada
       AND idcentrofichamedicapreauditada = elem.idcentrofichamedicapreauditada;
       

     IF elem.tipo = 14 or elem.tipo= 37 THEN 


              SELECT INTO elemriexiste * FROM recetarioitem WHERE centro = elem.centro and nrorecetario = elem.nroorden;
              IF FOUND THEN 
               SELECT INTO elemrecetario * FROM temprecetarioitem WHERE centro = elem.centro and nrorecetario = elem.nroorden;
                    UPDATE recetarioitem SET mnroregistro= elemrecetario.mnroregistro, idmotivodebito=elemrecetario.idmotivodebito
                                            , importe=elemrecetario.importe, importeapagar=elemrecetario.importeapagar, ridebito=elemrecetario.ridebito
                                            , importevigente=elemrecetario.importevigente, coberturaporplan=elemrecetario.coberturaporplan
                                            , coberturaefectiva =elemrecetario.coberturaefectiva
                    WHERE nrorecetario=elemriexiste.nrorecetario AND centro= elemriexiste.centro AND idrecetarioitem=elemriexiste.idrecetarioitem;
              END IF; 
    END IF; 

        IF elem.idauditoriatipo = 2 THEN 
            UPDATE fichamedicapreauditadaodonto SET idpiezadental = elem.idpiezadental
                                               ,idletradental = elem.idletradental
                                               ,idzonadental = elem.idzonadental
             WHERE idfichamedicapreauditadaodonto = elem.idfichamedicapreauditadaodonto
             AND idcentrofichamedicapreauditadaodonto = elem.idcentrofichamedicapreauditadaodonto;
        END IF;
       
       
       

END IF;


  -- MaLaPi 06-01-2012 Lo elimino, pues ya no se puede hacer en este sp, pues aun no se selecciono la facutra donde se van a vincular
    -- todas estas ordenes de un prestador.
    -- MaLaPi 11-10-2012 Vuelvo a Modificar para que verifique si se envia desde la aplicacion en nroregistro de una factura, en ese caso si se vincula

       IF not nullvalue(elem.nroregistro) THEN 
         SELECT INTO rfacturaordenesutilizadas * FROM facturaordenesutilizadas 
                                                 WHERE 
                                         --nroregistro = elem.nroregistro AND anio = elem.anio AND 
                                                 nroorden = elem.nroorden AND centro = elem.centro AND tipo=elem.tipo;

        IF FOUND THEN 
          DELETE FROM facturaordenesutilizadas WHERE nroorden = elem.nroorden AND centro = elem.centro AND tipo=elem.tipo;
        END IF;
        INSERT INTO facturaordenesutilizadas (nroregistro,anio,nroorden,centro,tipo) VALUES(elem.nroregistro,elem.anio,elem.nroorden,elem.centro,elem.tipo);

UPDATE ordenesutilizadas SET importe=(

SELECT sum(fmpaiimportes) AS imptotal FROM  fichamedicapreauditada   NATURAL JOIN (
                              SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada  FROM 
                              fichamedicapreauditadaitemconsulta
                              UNION
                              SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
                              FROM fichamedicapreauditadaitem  
                              NATURAL JOIN itemvalorizada 
                              UNION 
                              SELECT nrorecetario,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada  FROM 
                              fichamedicapreauditadaitemrecetario NATURAL JOIN recetarioitem  ) as ordenes

     WHERE nroorden =elem.nroorden AND centro = elem.centro AND tipo=elem.tipo)
     WHERE nroorden =elem.nroorden AND centro = elem.centro AND tipo=elem.tipo;



     /* 2013-01-21 hoy lo comento para realizar prueba de performance  
        SELECT INTO simportepagar * FROM calcularimporteauditadofactura(elem.nroregistro,elem.anio);

        UPDATE factura SET fimportepagar = simportepagar 
             WHERE anio = elem.anio AND nroregistro =elem.nroregistro; 
       */ 


 
     END IF;




FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;



return respuesta;
END;$function$
