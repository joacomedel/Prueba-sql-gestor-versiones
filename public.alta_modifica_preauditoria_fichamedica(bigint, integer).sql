CREATE OR REPLACE FUNCTION public.alta_modifica_preauditoria_fichamedica(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  
--KR modifico 19-2-15 para que busque los datos desde cada registro. Esta función se invoca en el sp cambiarestadosregistrosv1($1,$2,$3,$4)
  cursoritem CURSOR FOR 	
       SELECT /*nroordenpago,idcentroordenpago,*/fichamedica.idauditoriatipo, fichamedica.nrodoc,fichamedica.tipodoc, nombres as usunombre,apellido as usuapellido,fmpafechaingreso,idprestador,idfichamedica
	,idcentrofichamedica,fichamedicapreauditada.idcentrofichamedicaitem,fichamedicapreauditada.idfichamedicaitem,fmpaidusuario as idusuario,fichamedicapreauditada.idnomenclador,fichamedicapreauditada.idcapitulo,fichamedicapreauditada.idsubcapitulo,
	fichamedicapreauditada.idpractica,practica.pdescripcion as pradescripcion,prestador.pdescripcion as predescripcion,
	parafichamedicapreauditada.nroorden,parafichamedicapreauditada.centro,fichamedicapreauditada.fmpacantidad,
        fichamedicapreauditada.fmpadescripcion,
	fichamedicapreauditadaodonto.idpiezadental,fichamedicapreauditadaodonto.idletradental
        ,fichamedicapreauditadaodonto.idzonadental,
	parafichamedicapreauditada.idcentrofichamedicapreauditada AS idcentroregional
        ,idfichamedicapreauditada,idcentrofichamedicapreauditada
	FROM fichamedica JOIN fichamedicapreauditada  USING(idfichamedica,idcentrofichamedica) 	
	JOIN  fichamedicapreauditadaodonto USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
	JOIN  parafichamedicapreauditada USING(idfichamedicapreauditada,idcentrofichamedicapreauditada) 
        LEFT JOIN (SELECT nroregistro, anio FROM factura  WHERE nroregistro= $1 and anio=$2) as factura USING(nroregistro, anio)
	LEFT JOIN  ordenesutilizadas USING (nroorden, centro) 
        LEFT JOIN prestador USING(idprestador) 
        LEFT JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
	JOIN (SELECT dni as nrodoc, tipodoc, idusuario as fmpaidusuario, nombre as nombres, apellido FROM usuario ) as usuario USING(fmpaidusuario)
	WHERE nullvalue(fichamedicapreauditada.idfichamedicaitem) 
           AND nroregistro=   $1 and anio=$2;
    --nroordenpago = $1 AND idcentroordenpago = $2;
  
  idtipopres INTEGER;
  elem RECORD;
  verifica RECORD;
verificaitem RECORD;
  respuesta BOOLEAN;
  
 
BEGIN

respuesta = true;

open cursoritem;
FETCH cursoritem INTO elem;
WHILE FOUND LOOP

IF nullvalue(elem.idfichamedicaitem) THEN  
-- Siempre se van a dar de alta, cuando se modifique una preauditoria, no se va a reflejar el cambio en fichamedica

   INSERT INTO fichamedicaitem (fmifechaauditoria,idprestador,idusuario,fmiporreintegro,fmicantidad,fmidescripcion
            ,idfichamedica,idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica) 
    VALUES(elem.fmpafechaingreso,elem.idprestador,elem.idusuario,false,elem.fmpacantidad,'Desde Auditoria de Prestaciones',elem.idfichamedica
            ,elem.idcentrofichamedica,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica);

   elem.idfichamedicaitem = currval('public.fichamedicaitem_idfichamedicaitem_seq');
   elem.idcentrofichamedicaitem = centro();
   IF (elem.idnomenclador = '14') THEN -- Se trata de una auditoria de odonto
      INSERT INTO fichamedicaitemodonto (idpiezadental,idletradental,idfichamedicaitem,idcentrofichamedicaitem,idzonadental)
      VALUES(elem.idpiezadental,elem.idletradental,elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.idzonadental);
   END IF;

ELSE -- Se trata de la modificacion de un item de auditoria

     UPDATE fichamedicaitem SET  fmifechaauditoria = elem.fmpafechaingreso
            ,idprestador = elem.idprestador
            ,idusuario = elem.idusuario
            ,fmiporreintegro = false
            ,fmicantidad = elem.fmpacantidad
            ,fmidescripcion ='Desde Auditoria de Prestaciones'
            ,idnomenclador = elem.idnomenclador
            ,idcapitulo = elem.idcapitulo
            ,idsubcapitulo = elem.idsubcapitulo
            ,idpractica = elem.idpractica
     WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
           

     UPDATE fichamedicaitemodonto SET idpiezadental = elem.idpiezadental
            ,idletradental = elem.idletradental
            ,idzonadental = elem.idzonadental
     WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
   
 
END IF;



IF not nullvalue(elem.nroorden) THEN --Se emitio una orden, la tengo que registrar
    
    IF (elem.idauditoriatipo = 1) OR (elem.idauditoriatipo = 2) THEN
     -- Tipo Odontologia o Psicoterapia segun corresponda
        idtipopres = 6;
     ELSE
        idtipopres = 7;
     END IF;

       SELECT INTO verifica * FROM fichamedicaemision WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
       IF NOT FOUND THEN
                INSERT INTO fichamedicaemision(nrodoc,tipodoc,fmepfecha,idauditoriatipo,idfichamedicaitem
                ,idcentrofichamedicaitem,fmepcantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,tipoprestacion)
                VALUES(elem.nrodoc,elem.tipodoc,elem.fmpafechaingreso,elem.idauditoriatipo,elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.fmpacantidad,elem.idnomenclador
                ,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,idtipopres);
         ELSE 

                  UPDATE fichamedicaemision
                        SET
                        fmepcantidad = elem.fmpacantidad
                        ,idnomenclador = elem.idnomenclador
                        ,idcapitulo = elem.idcapitulo
                        ,idsubcapitulo = elem.idsubcapitulo
                        ,idpractica = elem.idpractica
                        ,tipoprestacion = idtipopres
                WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;

         
         END IF;
   
         UPDATE fichamedicaemisionestado SET fmeefechafin = now() WHERE idfichamedicaitem= elem.idfichamedicaitem
                                                             AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem
                                                             AND nullvalue(fmeefechafin);
         INSERT INTO fichamedicaemisionestado(idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaemisionestadotipo,fmeedescripcion,idauditoriatipo)
                VALUES (elem.idfichamedicaitem,elem.idcentrofichamedicaitem,2,'Al migrar preauditorias',elem.idauditoriatipo);
 
 
	SELECT INTO verificaitem * FROM fichamedicaitememisiones
                  WHERE idfichamedicaitem = elem.idfichamedicaitem  AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
                 IF FOUND THEN
                          UPDATE fichamedicaitememisiones SET  nroorden = elem.nroorden
                                , centro = elem.centro
                          WHERE idfichamedicaitem = elem.idfichamedicaitem AND idcentrofichamedicaitem = elem.idcentrofichamedicaitem;
   
                 ELSE
                          INSERT INTO fichamedicaitememisiones (idfichamedicaitem,idcentrofichamedicaitem,nroorden,centro)
                          VALUES (elem.idfichamedicaitem,elem.idcentrofichamedicaitem,elem.nroorden,elem.centro);
 
                 END IF;
END IF;

--Marco como guardada la fichamedicapreauditada

UPDATE fichamedicapreauditada SET idfichamedicaitem= elem.idfichamedicaitem
				,idcentrofichamedicaitem = elem.idcentrofichamedicaitem
WHERE idfichamedicapreauditada = elem.idfichamedicapreauditada AND idcentrofichamedicapreauditada = elem.idcentrofichamedicapreauditada;

FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;


return respuesta;
END;$function$
