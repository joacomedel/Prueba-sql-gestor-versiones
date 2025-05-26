CREATE OR REPLACE FUNCTION public.far_altamodificacionpediddo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
      
       cursoritempedido refcursor;
       rpedido record;
       ritempedido record;
       elitempedido record;
BEGIN

      SELECT INTO rpedido * FROM tmppedido;
      if (nullvalue(rpedido.idpedido)) THEN
         -- Crea pedido
         INSERT INTO far_pedido (pfechacreacion,pdescripcion,idprestador)
         VALUES (Now(),rpedido.pdescripcion,rpedido.idprestador);
         rpedido.idpedido = currval('public.far_pedido_idpedido_seq');
         rpedido.idcentropedido = centro();
         
      ELSE
          -- el pedido existe y se actualiza
          UPDATE far_pedido SET pdescripcion = rpedido.pdescripcion ,idprestador =rpedido.idprestador
          WHERE idpedido =  rpedido.idpedido and    idcentropedido = rpedido.idcentropedido;
          
      END IF;
    
      SELECT INTO cursoritempedido * FROM tmpitempedido;
      FETCH cursoritempedido into ritempedido;
      WHILE  found LOOP
             SELECT INTO elitempedido * FROM far_itempedido
             WHERE idpedido = rpedido.idpedido and    idcentropedido = rpedido.idcentropedido
                   and idarticulo =ritempedido.idarticulo;
             IF FOUND THEN
                      -- actualizo el item del pedido
                      UPDATE far_itempedido SET ipcantidad = ritempedido.ipcantidad
                      WHERE idpedido = rpedido.idpedido and    idcentropedido = rpedido.idcentropedido
                            and idarticulo =ritempedido.idarticulo;
             else
                 -- inserto el nuevo item del pedido
                      INSERT INTO far_itempedido (idpedido,idcentropedido,idarticulo,ipcantidad)
                      VALUES(rpedido.idpedido,rpedido.idcentropedido,rpedido.idarticulo , rpedido.ipcantidad);

             END IF;

             FETCH cursoritempedido into ritempedido;
      END loop;
      close cursoritempedido;
     
return 'true';
END;
$function$
