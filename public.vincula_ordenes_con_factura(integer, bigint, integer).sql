CREATE OR REPLACE FUNCTION public.vincula_ordenes_con_factura(integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  pidprestador alias for $1;
  pnroregistro alias for $2;
  panio alias for $3;
  respuesta BOOLEAN;
  cursoritem CURSOR FOR SELECT *  
                         FROM orden    
                         NATURAL JOIN ( SELECT idfichamedicapreauditada,idcentrofichamedicapreauditada,nroorden,centro FROM itemvalorizada NATURAL JOIN item  NATURAL JOIN fichamedicapreauditadaitem   
               UNION 
               SELECT idfichamedicapreauditada,idcentrofichamedicapreauditada,nroorden,centro FROM fichamedicapreauditadaitemconsulta ) as ordenesauditadas
NATURAL JOIN fichamedicapreauditada 
 
                         NATURAL JOIN ordenesutilizadas    
                         LEFT JOIN facturaordenesutilizadas USING(nroorden,centro)    
                         WHERE  nullvalue(facturaordenesutilizadas.nroorden)   
                         AND idprestador = pidprestador;
  elem RECORD;
  rfichamedica RECORD;
  rordenesusadas RECORD;
  rfichamedicapreauditadaitem RECORD;
  vidfichamedicapreauditada BIGINT;
  
 
BEGIN

respuesta = true;



open cursoritem;
FETCH cursoritem INTO elem;
WHILE FOUND LOOP

    SELECT INTO rordenesusadas * FROM facturaordenesutilizadas 
                                 WHERE nroorden = elem.nroorden AND centro = elem.centro;
    IF NOT FOUND THEN
       INSERT INTO facturaordenesutilizadas (nroregistro,anio,nroorden,centro)
        VALUES(pnroregistro,panio,elem.nroorden,elem.centro);
        
    ELSE 
       UPDATE facturaordenesutilizadas SET nroregistro = pnroregistro
                                           ,anio = panio
       WHERE nroorden = elem.nroorden  AND centro = elem.centro; 
        
    END IF;


FETCH cursoritem INTO elem;
END LOOP;
CLOSE cursoritem;

--24-02-2012 No verifico que exista el estado, pues puede ser que exista, pero no va a ser el Max idcambioestado
--,asumo que si vuelven a vincular ordenes de nuevo, lo van a queres volver a iniciar al procedimiento de nuevo. 

INSERT INTO festados(fechacambio,tipoestadofactura,anio,nroregistro,observacion)
VALUES(now(),1,panio,pnroregistro,'Modificado desde el Modulo de Gestion de Ordenes al vincular ordenes con facturas.');

return respuesta;
END;
$function$
