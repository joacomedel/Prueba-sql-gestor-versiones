CREATE OR REPLACE FUNCTION public.far_modificarconpreciosugerido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
	cursorarticulos CURSOR FOR SELECT *
                           FROM far_articulo_temp
                           NATURAL JOIN far_precioarticulosugerido
                           JOIN far_articulo USING(idarticulo,idcentroarticulo)
			   				WHERE nullvalue(pasfechafin);
                          
    rarticulo RECORD;
	rartexistente record;
	rprecioventa record;
	rprecioventasugerido record;
	elidarticulo bigint;
	rprecioventavalor double precision;
    elidajuste bigint;
    resp boolean;
    existelote record;
    rtipoiva RECORD;
    rprecioarticulopadre RECORD;
	vporcentaje double precision;
	vporcentajemasuno double precision;
	precio RECORD;
	rusuario RECORD;
                          
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
	   rusuario.idusuario = 25;
	END IF;
                           
	OPEN cursorarticulos;
	FETCH cursorarticulos into rarticulo;
	WHILE  found LOOP

		--Lo marco como ya procesado
		UPDATE far_precioarticulosugerido 
		SET pasfechafin = now(),pasmotivo = rarticulo.motivo
		WHERE 
			idarticulo = rarticulo.idarticulo 
			AND idcentroarticulo =rarticulo.idcentroarticulo 
			AND nullvalue(pasfechafin)
			AND idprecioarticulosugerido = rarticulo.idprecioarticulosugerido;

		IF rarticulo.accion <> 'eliminar' THEN

			SELECT INTO rprecioventa * 
			FROM far_precioarticulo 
			WHERE 
				idarticulo = rarticulo.idarticulo 
				AND idcentroarticulo =rarticulo.idcentroarticulo 
	            AND nullvalue(pafechafin);

			IF FOUND THEN
	           
		 		IF (CASE WHEN nullvalue(rprecioventa.pvalorcompra) THEN rprecioventa.pavalor ELSE rprecioventa.pvalorcompra END) <> rarticulo.pasvalorcompra THEN 
					--Malapi: Tener en cuenta que el campo pasvalorcompra en la tabla de precios guarda el precio de venta al publico
					--Malapi: Si el precio de venta es diferente al que esta guardado lo cambio. 
		     		UPDATE far_precioarticulo 
		     		SET pafechafin = now()
	                WHERE 
	                	idarticulo = rarticulo.idarticulo 
	                	AND idcentroarticulo =rarticulo.idcentroarticulo
	                	AND nullvalue(pafechafin);
	                    
	             	INSERT INTO far_precioarticulo(idarticulo, idcentroarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
	                VALUES(rarticulo.idarticulo,rarticulo.idcentroarticulo,now(),rarticulo.pasvalor,rarticulo.pasimporteiva , rarticulo.pasvalorcompra,rusuario.idusuario);

		 		END IF;
			ELSE --Existe el articulo pero no el precio de venta vigente
			
				INSERT INTO far_precioarticulo(idarticulo,idcentroarticulo, pafechaini,pavalor,pimporteiva,pvalorcompra,idusuariocarga)
	            VALUES(rarticulo.idarticulo,rarticulo.idcentroarticulo,now(),rarticulo.pasvalor,rarticulo.pasimporteiva , rarticulo.pasvalorcompra,rusuario.idusuario);

			END IF;
		END IF;
	
	fetch cursorarticulos into rarticulo;
	END LOOP;
	close cursorarticulos;

	return true;

END;$function$
