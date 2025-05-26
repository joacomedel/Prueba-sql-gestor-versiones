CREATE OR REPLACE FUNCTION public.far_abmstockajuste()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

     elidajuste  integer;
     elidcentroajuste  integer;
     cstockajuste CURSOR FOR SELECT *
                FROM temp_far_stockajusteitem;
     rstockajuste record;
    respuesta varchar;
    rusuario record;
    rtemp record;
    resp boolean;
    farm_sustock  record;
BEGIN

     
    


	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;
        elidajuste = 0;
	OPEN cstockajuste;
	FETCH cstockajuste into rstockajuste;
	WHILE  found LOOP

	IF nullvalue(rstockajuste.idstockajuste) AND (elidajuste = 0) THEN 
		INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion,saesautomatico)
                VALUES(false,now(),rstockajuste.sadescripcion,CASE WHEN nullvalue(rstockajuste.saesautomatico) THEN false ELSE true END);	
		elidajuste =  currval('far_stockajuste_idstockajuste_seq');	
		elidcentroajuste = centro();
		INSERT INTO far_stockajusteestado(idstockajusteestadotipo,idstockajuste,idcentrostockajuste,eaefechaini,idusuario)
		VALUES(1,elidajuste,centro(),now(),rusuario.idusuario);
	        --Lo voy a dejar en estado Creado, para que alguien lo tenga que cerrar
	ELSE 
		
                IF not nullvalue(rstockajuste.idstockajuste) THEN 
                     elidajuste =  rstockajuste.idstockajuste;	
		     elidcentroajuste = rstockajuste.idcentrostockajuste;
		     UPDATE far_stockajuste SET sadescripcion = rstockajuste.sadescripcion
					   ,saanulado = CASE WHEN nullvalue(rstockajuste.saanulado) THEN false ELSE true END
		     WHERE idstockajuste = elidajuste 
				AND idcentrostockajuste = elidcentroajuste;
                END IF;
	END IF;
	IF not nullvalue(rstockajuste.idarticulo) THEN --Genero los Items
		IF rstockajuste.operacion = 'eliminar' THEN 
			/*DELETE FROM far_stockajusteitem 
				WHERE idstockajuste = elidajuste 
				AND idcentrostockajuste = elidcentroajuste 
				AND idarticulo = rstockajuste.idarticulo 
				AND idcentroarticulo = rstockajuste.idcentroarticulo; 
				-- MaLaPi: 28-12-2017 No se puede eliminar de una tabla sincronizable, hay que poner la opercion en cero.*/
			UPDATE far_stockajusteitem SET idsigno = 1
							,saicantidad = 0
							,idusuario = rusuario.idusuario
							,saicantidadactual = 0
			WHERE idstockajuste = elidajuste 
				AND idcentrostockajuste = elidcentroajuste 
				AND idarticulo = rstockajuste.idarticulo 
				AND idcentroarticulo = rstockajuste.idcentroarticulo;  
				
		ELSE -- Inserto o modifico items
			UPDATE far_stockajusteitem SET idsigno = rstockajuste.idsigno
							,saicantidad = rstockajuste.saicantidad
							,idusuario = rusuario.idusuario
							,saicantidadactual = rstockajuste.saicantidadactual
			WHERE idstockajuste = elidajuste 
				AND idcentrostockajuste = elidcentroajuste 
				AND idarticulo = rstockajuste.idarticulo 
				AND idcentroarticulo = rstockajuste.idcentroarticulo;  
			IF NOT FOUND THEN 
				INSERT INTO far_stockajusteitem(idstockajuste,idcentrostockajuste,idsigno,saicantidad,idarticulo,idcentroarticulo,idusuario,saicantidadactual)
				VALUES(elidajuste,elidcentroajuste,rstockajuste.idsigno,rstockajuste.saicantidad,rstockajuste.idarticulo,rstockajuste.idcentroarticulo,rusuario.idusuario,rstockajuste.saicantidadactual);
				
			END IF;
		END IF;
			
	END IF;
	--Cambio de Estado
	IF rstockajuste.operacion = 'estado' THEN 
                          /********************/
                       -- CONTROLO QUE EL CENTRO DESDE EL QUE SE ESTA OPERANDO CON EL STOCK COINCIDA CON EL CENTRO DEL idcentrostockajuste
                       -- SI NO SE VERIFICA SE PRODUCE UNA EXCEPCION
                       --vas 230123
                           /********************/
                SELECT INTO farm_sustock   *  FROM centro() WHERE centro = elidcentroajuste;
                IF NOT FOUND THEN
                        RAISE EXCEPTION 'No se puede cambiar el estado de un comprobante de ajuste que no es del mismo centro.';
                END IF; 
               

                -- vas 230123


		UPDATE far_stockajusteestado SET eaefechafin = now()
						WHERE idstockajuste = elidajuste
						 AND idcentrostockajuste = elidcentroajuste;


		INSERT INTO far_stockajusteestado(idstockajusteestadotipo,idstockajuste,idcentrostockajuste,eaefechaini,idusuario)
		VALUES(rstockajuste.idstockajusteestadotipo,elidajuste,elidcentroajuste,now(),rusuario.idusuario);
		IF rstockajuste.idstockajusteestadotipo = 5 THEN 
		-- Hay que cerrar el Comprobante de Ajuste, generando los movimiento de Stock.

		CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
		INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)
		VALUES(concat('Comprobante de Ajuste ',elidajuste,'-',elidcentroajuste,' '),3);
		SELECT INTO resp far_movimientostocknuevo('far_stockajuste',concat(elidajuste::varchar,'|',elidcentroajuste));
	
		END IF;
	END IF;
          
       FETCH cstockajuste into rstockajuste;

    END LOOP;
    close cstockajuste;

-- MaLaPi 28-12-2017 Agregros los montos una sola vez al final
UPDATE far_stockajusteitem SET saiimporteunitario =t.saiimporteunitario 
				,saiimportetotal= t.saiimporteunitario * far_stockajusteitem.saicantidad
				,saialicuotaiva=t.saialicuotaiva 
				,saiimporteiva= t.saiimporteivaunit * far_stockajusteitem.saicantidad 
			FROM (SELECT idarticulo,idcentroarticulo,porcentaje as saialicuotaiva,pvalorcompra as saiimporteunitario,pimporteiva as saiimporteivaunit
 				FROM far_articulo 
				NATURAL JOIN tipoiva 
				NATURAL JOIN far_precioarticulo
				NATURAL JOIN temp_far_stockajusteitem
				WHERE nullvalue(pafechafin)) as t 
				 WHERE far_stockajusteitem.idarticulo = t.idarticulo 
					AND far_stockajusteitem.idcentroarticulo = t.idcentroarticulo    
				 	AND idstockajuste =elidajuste 
					AND idcentrostockajuste = elidcentroajuste;


   return concat(elidajuste,'-',elidcentroajuste) ;

END;
$function$
