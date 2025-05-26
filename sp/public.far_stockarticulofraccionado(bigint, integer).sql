CREATE OR REPLACE FUNCTION public.far_stockarticulofraccionado(bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
     pidarticulo  alias for $1;
     pidcentroarticulo  alias for $2;
     elidajuste INTEGER;
     rarticulo RECORD;
     rarticulopadre RECORD;
     rstockajuste record;
     resp boolean;
     rusuario record;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO rarticulo * FROM far_articulo
			NATURAL JOIN far_lote
			NATURAL JOIN far_precioarticulo
			WHERE idarticulo = pidarticulo 
			AND idcentroarticulo = pidcentroarticulo
			AND lstock <= 0 AND not nullvalue(idarticulopadre) 
			AND idcentrolote = centro()
			AND nullvalue(pafechafin);

IF FOUND THEN --El articulo tiene stock negativo y el hijo
	SELECT INTO rarticulopadre * FROM far_articulo
			NATURAL JOIN far_lote
			NATURAL JOIN far_precioarticulo
			WHERE idarticulo = rarticulo.idarticulopadre 
			AND idcentroarticulo = rarticulo.idcentroarticulopadre
			AND nullvalue(idarticulopadre) 
			AND idcentrolote = centro()
			AND nullvalue(pafechafin); 
	IF FOUND THEN --Encontre el articulo padre.

           INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion)
		VALUES(false, now(),concat('GA - Ajuste automatico del Articulo fraccionado :',rarticulo.adescripcion ,'-', rarticulo.acodigobarra));
           
	   elidajuste =  currval('far_stockajuste_idstockajuste_seq');
	   
           INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                  VALUES(5,elidajuste,centro(),now());
	   --Inserto los datos del Articulo padre - Resto en 1 el stock
           INSERT INTO far_stockajusteitem(idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
           VALUES (elidajuste, rarticulopadre.pavalor,-1,CASE WHEN nullvalue(rarticulopadre.afraccion) THEN 1 ELSE rarticulopadre.afraccion END,round((rarticulopadre.pavalor * rarticulopadre.afraccion)::numeric,2),rarticulopadre.idarticulo,rarticulopadre.idcentroarticulo,rarticulopadre.idiva,round((rarticulopadre.pimporteiva * rarticulopadre.afraccion)::numeric,2) ,rusuario.idusuario,rarticulopadre.lstock);
	
	   --Inserto los datos del Articulo Hijo - Sumo en 1 el stock
           INSERT INTO far_stockajusteitem(idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
           VALUES (elidajuste, rarticulo.pavalor,1,rarticulo.afraccion,round((rarticulo.pavalor * rarticulo.afraccion)::numeric,2),rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.idiva,round((rarticulo.pimporteiva * rarticulo.afraccion)::numeric,2) ,rusuario.idusuario,rarticulo.lstock);


                IF NOT iftableexists('far_movimientostocktmp') THEN
 		    CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
                ELSE 
                    DELETE FROM far_movimientostocktmp;
                END IF;
		INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Ajuste automatico del Articulo fraccionado, stock ajuste ' , elidajuste,'-',centro()) ,1);
		SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);

	END IF;
END IF;
    return concat(elidajuste,'-',centro());
    
END;$function$
