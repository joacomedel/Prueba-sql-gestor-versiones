CREATE OR REPLACE FUNCTION public.farmacia_existelote_crealote(pidarticulo bigint, pidcentroarticulo integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$declare
                       
	  existelote RECORD;
	  rarticulo RECORD;
	  elidajuste BIGINT;
	 resp boolean;
      
           rusuario RECORD; 
BEGIN

/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;
  

SELECT INTO existelote * FROM far_lote 
			  WHERE idarticulo = pidarticulo AND idcentroarticulo= pidcentroarticulo AND idcentrolote = centro();
IF NOT FOUND THEN 
	SELECT INTO rarticulo * FROM far_articulo 
				LEFT JOIN far_precioarticulo USING(idarticulo,idcentroarticulo)
				WHERE idarticulo = pidarticulo AND idcentroarticulo= pidcentroarticulo AND nullvalue(pafechafin); 
	IF FOUND THEN 
		INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('Alta de Lote para el Articulo ',now()));
		elidajuste =  currval('far_stockajuste_idstockajuste_seq');
		INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , eaefechaini)VALUES(5,elidajuste,now());
		INSERT INTO far_stockajusteitem(idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal
		,saialicuotaiva,saiimporteiva,saifechaingreso,idusuario,idarticulo,idcentroarticulo,saifechavencimiento)
		VALUES(elidajuste,rarticulo.pvalorcompra	,1,0,rarticulo.pvalorcompra,0,rarticulo.pvalorcompra
		,now(), rusuario.idusuario,rarticulo.idarticulo,rarticulo.idcentroarticulo,null);

		IF NOT  iftableexists('far_movimientostocktmp') THEN 
			CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
		ELSE
			DELETE FROM far_movimientostocktmp;
		END IF;
		INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)
		VALUES(concat('Alta de Articulo por far_abmarticulo',now(), 'IDAjuste ', elidajuste::varchar) ,1);
		SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);

	END IF;

END IF;


return 1;
END;$function$
