CREATE OR REPLACE FUNCTION public.far_ingresaitemspedidos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
CREATE TEMP TABLE tfar_pedidoitem (
				   idpedido BIGINT,
				   idcentropedido INTEGER ,
				   idarticulo  INTEGER ,
				   cantpedido  INTEGER,
				   idpedidoitem INTEGER,
				   preciocompra FLOAT
				 
				    );
*/
DECLARE

   	cursorarticulos CURSOR FOR SELECT * FROM tfar_pedidoitem
                               JOIN far_pedido USING(idpedido,idcentropedido)
                               LEFT JOIN far_articulo USING(idarticulo,idcentroarticulo);
	rarticulo RECORD;
	precio RECORD;
	rpedidoitem RECORD;
        rusuario RECORD;
        resp BOOLEAN;

BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

    OPEN cursorarticulos;
    FETCH cursorarticulos into rarticulo;
    WHILE  found LOOP
           SELECT INTO rpedidoitem * FROM far_pedidoitems 
                                     WHERE idarticulo = rarticulo.idarticulo 
                                           AND  idpedido = rarticulo.idpedido
                                           AND  idcentropedido = rarticulo.idcentropedido;
           IF NOT FOUND THEN 
                 INSERT INTO far_pedidoitems(idpedido,idcentropedido,idarticulo,picantidad,piidusuariocarga)
                               VALUES(rarticulo.idpedido,rarticulo.idcentropedido,rarticulo.idarticulo,rarticulo.cantpedido,rusuario.idusuario);      
           END IF;

           UPDATE far_pedidoitems SET picantidadentregada = rarticulo.cantpedido
                  WHERE idarticulo =rarticulo.idarticulo
                        and idpedido=rarticulo.idpedido
                        and idcentropedido=rarticulo.idcentropedido;

           IF (not nullvalue(rarticulo.preciocompra)) THEN
               --Malapi 20-03-2017 Para modificar el precio de compra, en caso de que haga falta.
		SELECT INTO resp * FROM far_abmpedido_modificarpreciocompra(rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.idpedido,rarticulo.idcentropedido);
                
                 /*SELECT INTO precio * FROM far_preciocompra
                 WHERE idarticulo = rarticulo.idarticulo
                 and nullvalue(pcfechafin);
                 
                 IF FOUND THEN
                       if(precio.preciocompra <>  rarticulo.preciocompra) THEN
                              UPDATE far_preciocompra SET pcfechafin = now()
                                     WHERE idarticulo =rarticulo.idarticulo
                                           and nullvalue(pcfechafin);
                               INSERT INTO far_preciocompra(idarticulo,idprestador,preciocompra,idusuariocarga)
                               VALUES(rarticulo.idarticulo,rarticulo.idprestador,rarticulo.preciocompra,rusuario.idusuario);

                          END IF;
                 ELSE
                         INSERT INTO far_preciocompra(idarticulo,idprestador,preciocompra,idusuariocarga)
                         VALUES(rarticulo.idarticulo,rarticulo.idprestador,rarticulo.preciocompra,rusuario.idusuario);

                 END IF;
                  */
              END IF; -- not nullvalue(rarticulo.preciocompra)
           
    fetch cursorarticulos into rarticulo;
    END LOOP;
    close cursorarticulos;

return 'true';
END;$function$
