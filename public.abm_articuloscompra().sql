CREATE OR REPLACE FUNCTION public.abm_articuloscompra()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
      
       carticulos refcursor;
 --RECORD
       rarticulos RECORD;
 --VARIABLES 
	elarticulo BIGINT;

BEGIN

	
    
      
      OPEN carticulos FOR SELECT * FROM temp_articulos;
      FETCH carticulos into rarticulos;
      WHILE found LOOP
             SELECT INTO elarticulo * FROM articulo  WHERE idarticulo = rarticulos.idarticulo;
             IF FOUND THEN
                      -- actualizo el articulo
			UPDATE articulo SET adescripcion = rarticulos.adescripcion 
					, nrocuentac=  rarticulos.nrocuentac 
                      WHERE idarticulo = rarticulos.idarticulo;

			 UPDATE agrupadorcompras_articulos SET idagrupador = rarticulos.idagrupador 					
                      WHERE idarticulo = rarticulos.idarticulo;
             ELSE
                 -- inserto el nuevo item del pedido
			INSERT INTO articulo (nrocuentac,adescripcion)
                      VALUES(rarticulos.nrocuentac, rarticulos.adescripcion);
			INSERT INTO agrupadorcompras_articulos (idagrupador,idarticulo)
                      VALUES(rarticulos.idagrupador, currval('public.articulo_idarticulo_seq')); 

             END IF;

      FETCH carticulos into rarticulos;
      END loop;
      close carticulos;
     
return 'true';
END;
$function$
