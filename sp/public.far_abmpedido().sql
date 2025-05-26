CREATE OR REPLACE FUNCTION public.far_abmpedido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    cursorarticulos CURSOR FOR SELECT *
                    FROM tfar_pedidoitem
                    LEFT JOIN far_articulo USING(idarticulo);

  rarticulo RECORD;
  pedidoitem RECORD;
        rusuario RECORD;
  resp BOOLEAN;

BEGIN

--GK 19-05-2023 se agrega control de idcentroarticulo al momento de manipular datos en far_pedidoitem 

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

    OPEN cursorarticulos;
    FETCH cursorarticulos into rarticulo;
    WHILE  found LOOP
                 
             IF nullvalue(rarticulo.idpedido) THEN
                  -- El pedido no existe, hay que generarlo.
                  IF nullvalue(rarticulo.fechadesde) THEN
                        -- Hay que generar un pedido sin productos
                        INSERT INTO far_pedido(pedescripcion,idprestador,pfechadesde,pfechahasta,pidusuariocarga)
                          ( SELECT pedescripcion,idprestador,rarticulo.fechadesde,rarticulo.fechahasta,rusuario.idusuario
                            FROM tfar_pedidoitem
                           );
                      
                      rarticulo.idpedido = currval('far_pedido_idpedido_seq'::regclass);
                      rarticulo.idcentropedido = centro();
                      -- Malapi 07/01/2014 Si es un Pedido vacio, se deja en estado entregado, pues se usa desde recibir items de pedidos.
                          
                      INSERT INTO far_pedidoestado(idestadotipo,idpedido)   VALUES(2,rarticulo.idpedido);
                  ELSE 
                      
                        INSERT INTO far_pedido(pedescripcion,idprestador,pfechadesde,pfechahasta,pidusuariocarga)
                          ( SELECT pedescripcion,idprestador,rarticulo.fechadesde,rarticulo.fechahasta,rusuario.idusuario
                            FROM tfar_pedidoitem
                           );
                        
                        rarticulo.idpedido = currval('far_pedido_idpedido_seq'::regclass);
                        rarticulo.idcentropedido = centro();

                        INSERT INTO far_pedidoestado(idestadotipo,idpedido)   VALUES(1,rarticulo.idpedido);
                        INSERT INTO far_pedidoitems(idpedido,idcentropedido,idarticulo,idcentroarticulo,picantidad,picantvendido,piidusuariocarga,piotrainformacion)
                    
                        ----KR 01-10-19 no es necesario el idtipopedido, hay rubros cuyo idtipopedido es nulo entonces no encuentra esos articulos. 
                        --KR 18-10-19 El rubro lo usan desde la interface para crear pedidos de perfumeria o de farmacia 
                      /*(SELECT rarticulo.idpedido,rarticulo.idcentropedido,idarticulo,idcentroarticulo,-1, SUM(ovicantidad) as acantvendido,rusuario.idusuario,far_info_cantidadarticulosvendidos(idarticulo,idcentroarticulo,rarticulo.fechadesde,rarticulo.fechahasta)     
                      FROM far_ordenventaitem         
                      NATURAL JOIN far_ordenventa
                      NATURAL JOIN far_ordenventatipo
                      NATURAL JOIN far_ordenventaestado         
                      WHERE far_ordenventaestado.ovefechafin is null 
                        AND ovfechaemision >= rarticulo.fechadesde
                        AND ovfechaemision <= rarticulo.fechahasta
                        AND idordenventaestadotipo <> 2 
                        AND ovtfacturable  
                        AND idcentroordenventa = centro() 
                      group by   rarticulo.idpedido,rarticulo.idcentropedido,idarticulo,idcentroarticulo, rusuario.idusuario);    
                      */                  

                      ( 
                        SELECT   rarticulo.idpedido,rarticulo.idcentropedido,idarticulo,idcentroarticulo,-1,acantvendido,rusuario.idusuario,far_info_cantidadarticulosvendidos(idarticulo,idcentroarticulo,rarticulo.fechadesde,rarticulo.fechahasta)
                        FROM far_articulo  NATURAL JOIN far_rubro 
                        JOIN      
                            (  
                              SELECT idcentroarticulo,idarticulo, SUM(ovicantidad) as acantvendido        
                              FROM far_ordenventaitem         
                              NATURAL JOIN far_ordenventa
                              NATURAL JOIN far_ordenventatipo
                              NATURAL JOIN far_ordenventaestado         
                              WHERE far_ordenventaestado.ovefechafin is null 
                                  AND ovfechaemision >= rarticulo.fechadesde
                                  AND ovfechaemision <= rarticulo.fechahasta
                                  AND idordenventaestadotipo <> 2 
                                  AND ovtfacturable  
                                  AND idcentroordenventa = centro() 
                              group by  idcentroarticulo,idarticulo        
                          ) as venta using (idarticulo,idcentroarticulo)  
                        WHERE  (idtipopedido = rarticulo.idtipopedido ) 
                      );
                  
                  END IF;
              
              ELSE  
                    -- El pedido existe, puede ser que necesiten modificar su cabecera
                    IF nullvalue(rarticulo.idarticulo) THEN
                      --Se necesita actualizar la cabecera del pedido
                        UPDATE far_pedido 
                            SET pedescripcion=rarticulo.pedescripcion
                                ,idprestador=rarticulo.idprestador
                                ,pfechadesde=rarticulo.fechadesde
                                ,pfechahasta=rarticulo.fechahasta
                                ,pidusuariocarga=rusuario.idusuario
                            WHERE 
                                idpedido = rarticulo.idpedido
                                AND idcentropedido = rarticulo.idcentropedido;

                        -- Cargo aqui la informacion extra si es que el pedido existe
                          UPDATE far_pedidoitems 
                            SET 
                              piotrainformacion = far_info_cantidadarticulosvendidos(idarticulo,idcentroarticulo,rarticulo.fechadesde,rarticulo.fechahasta)
                                                  
                          WHERE 
                            idpedido = rarticulo.idpedido
                            AND idcentropedido = rarticulo.idcentropedido
                            AND nullvalue(piotrainformacion);

             
                    END IF; 
              END IF;

             
             SELECT INTO pedidoitem * 
             FROM far_pedidoitems
             WHERE 
                idarticulo =rarticulo.idarticulo
                AND idcentroarticulo   =rarticulo.idcentroarticulo
                and idpedido=rarticulo.idpedido
                and idcentropedido=rarticulo.idcentropedido;
            
            IF FOUND THEN
                  if(rarticulo.cantpedido = 0)THEN
                        DELETE FROM far_pedidoitems
                        WHERE 
                            idarticulo =rarticulo.idarticulo
                            AND idcentroarticulo   =rarticulo.idcentroarticulo
                            and idpedido=rarticulo.idpedido
                            and idcentropedido=rarticulo.idcentropedido;
                  ELSE
                      UPDATE far_pedidoitems
                      SET picantidad =rarticulo.cantpedido
                      WHERE 
                        idarticulo =rarticulo.idarticulo
                        AND idcentroarticulo   =rarticulo.idcentroarticulo
                        and idpedido=rarticulo.idpedido
                        and idcentropedido=rarticulo.idcentropedido;
                  END IF;
          ELSE
                 IF NOT nullvalue(rarticulo.idarticulo) THEN 
                    INSERT INTO far_pedidoitems(idpedido,idcentropedido,idarticulo,idcentroarticulo,picantidad,piidusuariocarga)
                    VALUES(rarticulo.idpedido,rarticulo.idcentropedido,rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.cantpedido,rusuario.idusuario);
                 END IF;
          END IF;

    --Malapi 20-03-2017 Para modificar el precio de compra, en caso de que haga falta.
    SELECT INTO resp * FROM far_abmpedido_modificarpreciocompra(rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.idpedido,rarticulo.idcentropedido);
                 fetch cursorarticulos into rarticulo;
    END LOOP;
    close cursorarticulos;

return 'true';
END;$function$
