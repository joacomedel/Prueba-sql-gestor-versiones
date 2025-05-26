CREATE OR REPLACE FUNCTION public.far_abmpedido_desde_faltante()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE

	vidpedido INTEGER;
	rusuario RECORD;

BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


  INSERT INTO far_pedido(pedescripcion,idprestador,pidusuariocarga)
    ( SELECT 'G.A. desde faltantes',idprestador,rusuario.idusuario
                          FROM tfar_pedidoitem 
                         );
  vidpedido = currval('far_pedido_idpedido_seq'::regclass);
  INSERT INTO far_pedidoestado(idestadotipo,idpedido)   VALUES(1,vidpedido);


   INSERT INTO far_pedidoitems(idpedido,idcentropedido,idarticulo,idcentroarticulo,picantidad,picantvendido,piidusuariocarga)
                        ( SELECT   vidpedido,centro(),far_articulo.idarticulo,far_articulo.idcentroarticulo,cantpedido,0,rusuario.idusuario
			FROM tfar_pedidoitem JOIN far_articulo ON(acodbarra=acodigobarra)
			);



     

return vidpedido;
END;$function$
