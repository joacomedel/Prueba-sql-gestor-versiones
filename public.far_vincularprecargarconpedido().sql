CREATE OR REPLACE FUNCTION public.far_vincularprecargarconpedido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    cursorprecarga REFCURSOR; 
    cursorcomprobantes REFCURSOR; 

    relem RECORD;
    rdatos RECORD;
    aundisponible RECORD;
    precio RECORD;
    resprecio RECORD;
    verificacantidad RECORD;
    respuesta boolean;

    didusuario INTEGER;

BEGIN

respuesta = true;
didusuario = 0;

--Malapi 09-11-2017 Verifico que la suma de los productos entregados en los comprobantes se corresponda con la cantidad que figura como entregada en el pedido
--es decir far_precargarpedido.pcpcantidad sea igual a sum(far_precargarpedidocomprobantearticulo.pcpcacantidad) para ese usuario. 

SELECT INTO verificacantidad *  
FROM (
    SELECT 
        pc.idusuario,
        pc.idarticulo,
        pc.idcentroarticulo,
        pc.pcpcantidad as pcantidadentregapedido,
        sum(CASE WHEN nullvalue(pcpcacantidad) THEN 0 ELSE pcpcacantidad END) as cantidadcomprabantes
        --GK 08-07-2022
        --,pcca.idprecargarpedidocompcatalogo
        --,pcca.idcentroprecargarpedidocompcatalogo
    FROM tfar_precarga as tpc
    JOIN far_precargarpedido pc ON tpc.idusuario = pc.idusuario AND nullvalue(pc.idpedidoitem) AND pcpcantidad>0
    LEFT JOIN far_precargarpedidocomprobantearticulo as pcca USING(idprecargarpedido,idcentroprecargapedido)
    GROUP BY pc.idusuario,pc.idarticulo,pc.idcentroarticulo,pc.pcpcantidad--,pcca.idprecargarpedidocompcatalogo,pcca.idcentroprecargarpedidocompcatalogo
    ORDER BY pc.idarticulo
    ) as t
NATURAL JOIN far_articulo
WHERE cantidadcomprabantes <> pcantidadentregapedido
LIMIT 1;

IF FOUND THEN 

    RAISE EXCEPTION 'Los productos entregados en los comprobantes No se corresponda con la cantidad que figura como entregada en la precarga. Por ejemplo: %', concat(verificacantidad.cantidadcomprabantes,' <> ',verificacantidad.pcantidadentregapedido,' para ',verificacantidad.adescripcion) USING HINT = 'Eliminar las ordenes vinculadas antes de proceder.';

    respuesta = false;

ELSE 





        --Cargo los productos que ESTAN en alguno de los pedidos.
        OPEN cursorprecarga FOR 
                SELECT 
                    pi.idpedidoitem,
                    pi.idcentropedidoitem,
                    CASE WHEN nullvalue(pi.idpedido) THEN tpc.idpedido ELSE pi.idpedido END as idpedido,
                    CASE WHEN nullvalue(pi.idcentropedido) THEN tpc.idcentropedido ELSE pi.idcentropedido END as idcentropedido ,
                    pi.picantidad,
                    pi.picantidadentregada,
                    pc.idusuario,
                    pc.idarticulo,
                    pc.idcentroarticulo,
                    pc.pcpcantidad,
                    pc.pcppreciocompra,
                    p.idprestador,
                    pc.pcpprecioventasiniva,
                    pc.pcpprecioventaconiva
                FROM tfar_precarga as tpc
                NATURAL JOIN far_pedido as p
                JOIN far_precargarpedido pc ON tpc.idusuario = pc.idusuario AND nullvalue(pc.idpedidoitem) AND pcpcantidad>0
                JOIN far_pedidoitems as pi 
                    ON pi.idarticulo = pc.idarticulo 
                    AND pi.idcentroarticulo = pc.idcentroarticulo
                    AND p.idpedido = pi.idpedido
                    AND p.idcentropedido = pi.idcentropedido
                ORDER BY pc.idarticulo;

            FETCH cursorprecarga into relem;
            WHILE  found LOOP
        -- Malapi 07-03-2014 Tengo que verificar si esa precarga aun esta sin procesar, pues si ya se vinculo a otro pedido, no tengo que hacer mas nada. 
                     SELECT INTO  aundisponible * 
                                               FROM far_precargarpedido 
                                               WHERE idarticulo = relem.idarticulo
                                                     AND idusuario = relem.idusuario
                                                    AND nullvalue(idpedidoitem) ;

                     IF FOUND THEN 

                         IF NOT nullvalue(relem.idpedidoitem) THEN 
                         --Si esta en el pedido, le modifico la cantidad entregada
                         --Vinculo a la precarga este item

                                     UPDATE far_precargarpedido 
                                          SET idpedidoitem = relem.idpedidoitem
                                              ,idcentropedido = relem.idcentropedido
                                              ,idpedido = relem.idpedido
                                     WHERE idusuario =relem.idusuario 
                                           AND idarticulo = relem.idarticulo AND idcentroarticulo = relem.idcentroarticulo 
                                           AND nullvalue(idpedidoitem) ;

                                       IF FOUND THEN 
                                       -- solo modifico la cantidad entregada si es que la precarga se vincula la item de pedido. 
                                       
                                          UPDATE far_pedidoitems
                                          SET picantidadentregada =(CASE WHEN NULLVALUE(picantidadentregada) THEN 0 
                                                                     ELSE picantidadentregada END)   +relem.pcpcantidad
                                          WHERE idarticulo =relem.idarticulo AND idcentroarticulo = relem.idcentroarticulo 
                                            and idpedido=relem.idpedido
                                            and idcentropedido=relem.idcentropedido
                                            AND idpedidoitem = relem.idpedidoitem;

                                      END IF;
                                     

                        ELSE -- Si no existe en el pedido, lo agrego
                         
                                       INSERT INTO far_pedidoitems(idpedido,idcentropedido,idarticulo,idcentroarticulo,picantidad,picantidadentregada,piidusuariocarga)
                                       VALUES(relem.idpedido,relem.idcentropedido,relem.idarticulo,relem.idcentroarticulo ,relem.pcpcantidad,relem.pcpcantidad,relem.idusuario);
                                       
                                       UPDATE far_precargarpedido 
                                          SET idpedidoitem = currval('far_pedidoitems_idpedidoitem_seq'::regclass)
                                              ,idcentropedido = relem.idcentropedido
                                              ,idpedido = relem.idpedido
                                       WHERE idusuario =relem.idusuario AND idarticulo = relem.idarticulo  AND idcentroarticulo = relem.idcentroarticulo 
                                       AND nullvalue(idpedidoitem);
                                       
                         END IF;

                        IF (not nullvalue(relem.pcppreciocompra) OR not nullvalue(relem.pcpprecioventasiniva) OR not nullvalue(relem.pcpprecioventaconiva)) THEN
                                   SELECT INTO resprecio * FROM far_guardarpreciocompradesdepedido(relem.idarticulo,relem.idcentroarticulo,relem.idprestador,relem.pcppreciocompra,relem.pcpprecioventasiniva,relem.pcpprecioventaconiva,relem.idusuario);  
                        END IF;



                    END IF;           
                     
                     fetch cursorprecarga into relem;
            END LOOP;
            close cursorprecarga;


            -- Cargo los productos que NO estan en ninguno de los pedidos
             OPEN cursorprecarga FOR 
                SELECT 
                    pi.idpedidoitem,
                    pi.idcentropedidoitem,
                    CASE WHEN nullvalue(pi.idpedido) THEN tpc.idpedido ELSE pi.idpedido END as idpedido,
                    CASE WHEN nullvalue(pi.idcentropedido) THEN tpc.idcentropedido ELSE pi.idcentropedido END as idcentropedido ,
                    pi.picantidad,
                    pi.picantidadentregada,
                    pc.idusuario,
                    pc.idarticulo,
                    pc.idcentroarticulo,
                    pc.pcpcantidad,
                    pc.pcppreciocompra,
                    p.idprestador,
                    pc.pcpprecioventasiniva,
                    pc.pcpprecioventaconiva
                FROM tfar_precarga as tpc
                NATURAL JOIN far_pedido as p
                JOIN far_precargarpedido pc ON tpc.idusuario = pc.idusuario AND nullvalue(pc.idpedidoitem) AND pcpcantidad>0
                LEFT JOIN far_pedidoitems as pi 
                    ON pi.idarticulo = pc.idarticulo 
                    AND pi.idcentroarticulo = pc.idcentroarticulo
                    AND p.idpedido = pi.idpedido
                    AND p.idcentropedido = pi.idcentropedido
                WHERE nullvalue(pi.idpedidoitem) 
                ORDER BY pc.idarticulo;

                FETCH cursorprecarga into relem;
                WHILE  found LOOP
            -- Malapi 07-03-2014 Tengo que verificar si esa precarga aun esta sin procesar, pues si ya se vinculo a otro pedido, no tengo que hacer mas nada. 
                        SELECT INTO  aundisponible * 
                                                   FROM far_precargarpedido 
                                                   WHERE idarticulo = relem.idarticulo AND idcentroarticulo = relem.idcentroarticulo 
                                                         AND idusuario = relem.idusuario
                                                        AND nullvalue(idpedidoitem);

                         IF FOUND THEN 

                             IF NOT nullvalue(relem.idpedidoitem) THEN 
                             --Si esta en el pedido, le modifico la cantidad entregada
                             --Vinculo a la precarga este item

                                         UPDATE far_precargarpedido 
                                              SET idpedidoitem = relem.idpedidoitem
                                                  ,idcentropedido = relem.idcentropedido
                                                  ,idpedido = relem.idpedido
                                         WHERE idusuario =relem.idusuario 
                                               AND idarticulo = relem.idarticulo AND idcentroarticulo = relem.idcentroarticulo
                                               AND nullvalue(idpedidoitem);

                                           IF FOUND THEN 
                                           -- solo modifico la cantidad entregada si es que la precarga se vincula la item de pedido. 
                                           
                                              UPDATE far_pedidoitems
                                              SET picantidadentregada =(CASE WHEN NULLVALUE(picantidadentregada) THEN 0 
                                                                         ELSE picantidadentregada END) +relem.pcpcantidad
                                              WHERE idarticulo =relem.idarticulo AND idcentroarticulo = relem.idcentroarticulo 
                                                and idpedido=relem.idpedido
                                                and idcentropedido=relem.idcentropedido
                                                AND idpedidoitem = relem.idpedidoitem;

                                          END IF;
                                         

                             ELSE -- Si no existe en el pedido, lo agrego
                             
                                           INSERT INTO far_pedidoitems(idpedido,idcentropedido,idarticulo,idcentroarticulo,picantidad,picantidadentregada,piidusuariocarga)
                                           VALUES(relem.idpedido,relem.idcentropedido,relem.idarticulo,relem.idcentroarticulo ,relem.pcpcantidad,relem.pcpcantidad,relem.idusuario);
                                           
                                           UPDATE far_precargarpedido 
                                              SET idpedidoitem = currval('far_pedidoitems_idpedidoitem_seq'::regclass)
                                                  ,idcentropedido = relem.idcentropedido
                                                  ,idpedido = relem.idpedido
                                           WHERE idusuario =relem.idusuario AND idarticulo = relem.idarticulo AND idcentroarticulo = relem.idcentroarticulo 
                                                    AND nullvalue(idpedidoitem);
                                           
                             END IF;


                            IF (not nullvalue(relem.pcppreciocompra) OR not nullvalue(relem.pcpprecioventasiniva) OR not nullvalue(relem.pcpprecioventaconiva)) THEN
                                       SELECT INTO resprecio * FROM far_guardarpreciocompradesdepedido(relem.idarticulo,relem.idcentroarticulo,relem.idprestador,relem.pcppreciocompra,relem.pcpprecioventasiniva,relem.pcpprecioventaconiva,relem.idusuario);  
                            END IF;  
                         
                    END IF;    
                         
                         
                    fetch cursorprecarga into relem;
                
                END LOOP;
                close cursorprecarga;

        --GK 20-09-2022 desactivo los comprobantes vinculas a las precargas 
        OPEN cursorcomprobantes FOR
            SELECT idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo,idusuario
            FROM tfar_precarga 
            LEFT JOIN far_precargarpedido USING (idpedido,idcentropedido,idusuario)
            LEFT JOIN far_precargarpedidocomprobantearticulo using(idprecargarpedido,idcentroprecargapedido)

            GROUP BY idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo,idusuario;


        FETCH cursorcomprobantes into rdatos;
        WHILE  found LOOP


            UPDATE far_precargarpedidocompcatalogo
            SET pcpccactivo =false
            WHERE
                idprecargarpedidocompcatalogo=rdatos.idprecargarpedidocompcatalogo
                AND idcentroprecargarpedidocompcatalogo=rdatos.idcentroprecargarpedidocompcatalogo;

            IF didusuario=0 THEN 
                didusuario=rdatos.idusuario;
            END IF;

            fetch cursorcomprobantes into rdatos;
                
        END LOOP;
        close cursorcomprobantes;

        -- Limpiar precargas de usuario 
        UPDATE far_precargapedido_articulo SET fechauso=now() WHERE nullvalue(fechauso) AND idusuario=didusuario;

END IF; -- Verifico que se corresponda la cantidad de los comprabantes con la del pedido

return respuesta;
END;$function$
