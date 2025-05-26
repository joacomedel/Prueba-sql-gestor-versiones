CREATE OR REPLACE FUNCTION public.far_abmpedido_modificarpreciocompra(bigint, integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	pidarticulo alias for $1;
	pidcentroarticulo alias for $2;
	pidpedido alias for $3;
	pidcentropedido alias for $4;
   	cursorarticulos refcursor;
   	
	rarticulo RECORD;
	rprecarga RECORD;
	resp BOOLEAN;
        rusuario RECORD;

BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

    OPEN cursorarticulos FOR SELECT *
                    FROM tfar_pedidoitem
                    LEFT JOIN far_articulo USING(idarticulo,idcentroarticulo)
                    LEFT JOIN far_preciocompra USING(idarticulo,idcentroarticulo)
                    WHERE idarticulo = pidarticulo AND idcentroarticulo = pidcentroarticulo
                          AND nullvalue(pcfechafin) 
                          AND far_preciocompra.preciocompra <> tfar_pedidoitem.preciocompra;
    FETCH cursorarticulos into rarticulo;
    WHILE  found LOOP
		 
		SELECT INTO resp * FROM far_guardarpreciocompradesdepedido(rarticulo.idarticulo,
								rarticulo.idcentroarticulo,
								rarticulo.idprestador,
								rarticulo.preciocompra,
								null,
								null,
								rusuario.idusuario);
		
		UPDATE far_precargarpedido SET pcppreciocompra = rarticulo.preciocompra 
			WHERE pcppreciocompra <>  rarticulo.preciocompra  AND (idprecargarpedido,idcentroprecargapedido) IN 
			(SELECT idprecargarpedido,idcentroprecargapedido
			FROM far_pedidoitems 
			NATURAL JOIN far_precargarpedido
			where idpedido = pidpedido AND idcentropedido =  pidcentropedido AND 
			idarticulo = pidarticulo AND idcentroarticulo = pidcentroarticulo);
    fetch cursorarticulos into rarticulo;
    END LOOP;
    close cursorarticulos;

return 'true';
END;$function$
