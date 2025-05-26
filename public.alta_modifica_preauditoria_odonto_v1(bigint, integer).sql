CREATE OR REPLACE FUNCTION public.alta_modifica_preauditoria_odonto_v1(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  cursoritem CURSOR FOR SELECT * FROM  fichamedicapreauditada_fisica 
                        WHERE nroorden=$1 AND centro=$2 
                        ORDER BY idfichamedicapreauditada_fisica;
  
  estadorecetario RECORD;
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
  vtipo integer;
  elem2 RECORD;
  rverificaprestador RECORD;
 
BEGIN



respuesta = true;

open cursoritem;
FETCH cursoritem INTO elem;

IF FOUND THEN 

vtipo = elem.tipo;

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
      fmpaimportedebito,fmpadescripciondebito,idmotivodebitofacturacion,tipo)
      VALUES(elem.fmpaporeintegro,0,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica
      ,elem.fmpacantidad,elem.fmpaidusuario,CURRENT_TIMESTAMP,rfichamedica.idfichamedica,rfichamedica.idcentrofichamedica,elem.fmpadescripcion
      ,elem.fmpaiimportes,elem.fmpaiimporteiva,elem.fmpaiimportetotal,
      elem.importedebito,elem.descripciondebito,elem.idmotivodebitofacturacion, elem.tipo);

      vidfichamedicapreauditada = currval('fichamedicapreauditada_idfichamedicapreauditada_seq'::regclass);

      
     -- SELECT INTO rorden * FROM orden WHERE nroorden = elem.nroorden AND centro = elem.centro;

      IF elem.tipo = 4 THEN
        INSERT INTO fichamedicapreauditadaitemconsulta (nroorden,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingres)
        VALUES(elem.nroorden,elem.centro,vidfichamedicapreauditada,centro(),CURRENT_TIMESTAMP);
       
      ELSE 
        IF elem.tipo = 14 or elem.tipo= 37 THEN 
               SELECT INTO elemrecetario * FROM temprecetarioitem WHERE mnroregistro = elem.iditem AND centro = elem.centro and nrorecetario = elem.nroorden;
               INSERT INTO recetarioitem(nrorecetario, centro, nomenclado,mnroregistro, idmotivodebito, importe, importeapagar, ridebito
                                        , importevigente, coberturaporplan, coberturaefectiva ) 
               VALUES (elemrecetario.nrorecetario, elemrecetario.centro, elemrecetario.nomenclado,elemrecetario.mnroregistro,elemrecetario.idmotivodebito
                     ,elemrecetario.importe,elemrecetario.importeapagar,elemrecetario.ridebito
                     ,elemrecetario.importevigente,elemrecetario.coberturaporplan,elemrecetario.coberturaefectiva);
               elidrecetarioitem =  currval('recetarioitem_idrecetarioitem_seq');
               INSERT INTO fichamedicapreauditadaitemrecetario 
               (idrecetarioitem,idcentrorecetarioitem,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingreso)
               VALUES(elidrecetarioitem,centro(),elemrecetario.centro,vidfichamedicapreauditada,centro(),CURRENT_TIMESTAMP);

               UPDATE fichamedicapreauditada SET mnroregistro= elemrecetario.mnroregistro
                                    ,nomenclado=elemrecetario.nomenclado
                WHERE idfichamedicapreauditada = vidfichamedicapreauditada
                AND idcentrofichamedicapreauditada = centro();
                ---EL ESTADO DEL RECETARIO ES 2= USADO
                SELECT INTO estadorecetario * FROM recetarioestados 
                       WHERE nrorecetario= elemrecetario.nrorecetario AND centro= elemrecetario.centro AND nullvalue(refechafin);
               
                IF FOUND AND  estadorecetario.idtipocambioestado <> 2 THEN
                      INSERT INTO recetarioestados (refechamodificacion,idtipocambioestado,redescripcion,nrorecetario,centro) 
                      VALUES(CURRENT_DATE, 2, 'Ingresado desde SP alta_modifica_preauditoria_odonto', elemrecetario.nrorecetario, elemrecetario.centro);
	        END IF;


        ELSE 
               INSERT INTO fichamedicapreauditadaitem 
                (nroorden,iditem,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingreso)
                VALUES(elem.nroorden,elem.iditem,elem.centro,vidfichamedicapreauditada, centro(),CURRENT_TIMESTAMP);
       
         END IF;
      END IF;
      IF elem.idauditoriatipo = 2 THEN 
          INSERT INTO fichamedicapreauditadaodonto (idpiezadental,idletradental,idzonadental,idfichamedicapreauditada,idcentrofichamedicapreauditada)
      VALUES(elem.idpiezadental,elem.idletradental,elem.idzonadental,vidfichamedicapreauditada,centro());
      END IF;

ELSE
      /*Malapi 12-10-2012 Comento la modificacion a fmpafechaingreso pues no se si es mejor que quede el dia que se cargo inicialmente o la ultima vez que se toco*/
/*En modulo auditoria odontologica/Psico muestro fecha auditoria, lo tomo de fmpafechaingreso pq solo queda el dia que se cargo inicialmente.....*/
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
      SELECT INTO elemrecetario * FROM temprecetarioitem WHERE mnroregistro = elem.iditem AND centro = elem.centro and nrorecetario = elem.nroorden;
      
      SELECT INTO elemriexiste * FROM recetarioitem WHERE centro = elem.centro and nrorecetario = elem.nroorden and mnroregistro = elem.iditem;
   
        IF FOUND THEN 
                     UPDATE recetarioitem SET mnroregistro= elemrecetario.mnroregistro, idmotivodebito=elemrecetario.idmotivodebito
                                            , importe=elemrecetario.importe, importeapagar=elemrecetario.importeapagar, ridebito=elemrecetario.ridebito
                                            , importevigente=elemrecetario.importevigente, coberturaporplan=elemrecetario.coberturaporplan
                                            , coberturaefectiva =elemrecetario.coberturaefectiva
                    WHERE nrorecetario=elemriexiste.nrorecetario AND centro= elemriexiste.centro AND idrecetarioitem=elemriexiste.idrecetarioitem;
        ELSE 

              -- SELECT INTO elemrecetario * FROM temprecetarioitem WHERE mnroregistro = elem.iditem AND centro = elem.centro and nrorecetario = elem.nroorden;
               INSERT INTO recetarioitem(nrorecetario, centro, mnroregistro, idmotivodebito, importe, importeapagar, ridebito
                                        , importevigente, coberturaporplan, coberturaefectiva ) 
               VALUES (elemrecetario.nrorecetario, elemrecetario.centro,elemrecetario.mnroregistro,elemrecetario.idmotivodebito
                     ,elemrecetario.importe,elemrecetario.importeapagar,elemrecetario.ridebito
                     ,elemrecetario.importevigente,elemrecetario.coberturaporplan,elemrecetario.coberturaefectiva);
               elidrecetarioitem =  currval('recetarioitem_idrecetarioitem_seq');

               INSERT INTO fichamedicapreauditadaitemrecetario 
               (idrecetarioitem,idcentrorecetarioitem,centro,idfichamedicapreauditada,idcentrofichamedicapreauditada,fmpaifechaingreso)
               VALUES(elidrecetarioitem,centro(),elemrecetario.centro,elem.idfichamedicapreauditada, elem.idcentrofichamedicapreauditada,CURRENT_TIMESTAMP);

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




FETCH cursoritem INTO elem;
END LOOP;

END IF; -- IF FOUND THEN
CLOSE cursoritem;

SELECT INTO elem2 * FROM fichamedicapreauditada_fisica 
                        WHERE nroorden=$1 AND centro=$2 
                        ORDER BY idfichamedicapreauditada_fisica LIMIT 1;

  -- MaLaPi 06-01-2012 Lo elimino, pues ya no se puede hacer en este sp, pues aun no se selecciono la facutra donde se van a vincular
    -- todas estas ordenes de un prestador.
    -- MaLaPi 11-10-2012 Vuelvo a Modificar para que verifique si se envia desde la aplicacion en nroregistro de una factura, en ese caso si se vincula

      IF not nullvalue(elem2.nroregistro) THEN 
         SELECT INTO rfacturaordenesutilizadas * FROM facturaordenesutilizadas 
                                                 WHERE 
                                                  nroorden = elem2.nroorden AND centro = elem2.centro AND tipo=elem2.tipo;

        IF FOUND THEN 
          UPDATE facturaordenesutilizadas SET nroregistro =elem2.nroregistro ,anio = elem2.anio 
          WHERE nroorden = elem2.nroorden AND centro = elem2.centro AND tipo=elem2.tipo;
        ELSE  
          INSERT INTO facturaordenesutilizadas (nroregistro,anio,nroorden,centro,tipo) VALUES(elem2.nroregistro,elem2.anio,elem2.nroorden,elem2.centro,elem2.tipo);

        END IF;

UPDATE ordenesutilizadas SET importe=(

SELECT sum(fmpaiimportes) AS imptotal FROM  fichamedicapreauditada   NATURAL JOIN (
                              SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada  FROM 
                              fichamedicapreauditadaitemconsulta
                              UNION
                              SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
                              FROM fichamedicapreauditadaitem  
                              NATURAL JOIN itemvalorizada 
                              UNION 
                              SELECT nrorecetario as nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada  FROM 
                              fichamedicapreauditadaitemrecetario NATURAL JOIN recetarioitem  ) as ordenes

     WHERE nroorden =$1 AND centro = $2 AND tipo=vtipo)
     WHERE nroorden =$1 AND centro = $2 AND tipo=vtipo;




 
     END IF;




 DELETE FROM fichamedicapreauditada_fisica WHERE nroorden=$1 AND centro=$2 AND tipo=vtipo;

return respuesta;
END;$function$
