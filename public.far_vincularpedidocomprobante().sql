CREATE OR REPLACE FUNCTION public.far_vincularpedidocomprobante()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       cpedidoreclibrofac CURSOR FOR SELECT * 
                                     FROM tfar_pedidoreclibrofac 
                                     NATURAL JOIN far_pedido;
       unpedidocomp record;
       resp refcursor;
       
BEGIN

     open cpedidoreclibrofac;
     FETCH cpedidoreclibrofac into unpedidocomp;
     WHILE  found LOOP

               UPDATE far_pedidoreclibrofact SET prcomentario = unpedidocomp.elcomentario 
                 WHERE numeroregistro = unpedidocomp.numeroregistro AND anio = unpedidocomp.anio
                     AND idpedido = unpedidocomp.idpedido AND idcentropedido = unpedidocomp.idcentropedido;
               IF NOT FOUND THEN 
                    INSERT INTO far_pedidoreclibrofact (idpedido,idcentropedido,numeroregistro,anio,prcomentario)
                    VALUES (unpedidocomp.idpedido,unpedidocomp.idcentropedido,unpedidocomp.numeroregistro,unpedidocomp.anio,unpedidocomp.elcomentario);
               END IF;
              
          IF existecolumtemp('tfar_pedidoreclibrofac','numerofacturatext') THEN
          -- MaLaPi 11/08/2017 Intento modificar lo cargado en farmacia para que quede registrado el Nro.Registro de las facturas
                UPDATE far_precargarpedidocomprobante 
                   SET numeroregistro = unpedidocomp.numeroregistro, anio = unpedidocomp.anio
                   WHERE idprestador = unpedidocomp.idprestador 
                    AND trim(concat(tipofactura,' ',letra,' ',numfactura)) = unpedidocomp.numerofacturatext;
          END IF;
          /* Modifico el estado del pedido **/
          SELECT INTO resp far_cambiarestadopedido(concat(unpedidocomp.idpedido,'|',unpedidocomp.idcentropedido),6);
          FETCH cpedidoreclibrofac into unpedidocomp;

     END LOOP;

      close cpedidoreclibrofac;
return 'true';
END;
$function$
