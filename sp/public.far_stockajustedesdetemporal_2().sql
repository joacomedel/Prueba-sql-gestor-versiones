CREATE OR REPLACE FUNCTION public.far_stockajustedesdetemporal_2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    elidajuste  integer;
    respuesta varchar;
    rusuario record;
    rstockajuste record;
     elidcentroajuste  integer;
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

      --Genero el Comprobante de Ingreso
	SELECT INTO rstockajuste * FROM temp_far_stockajusteitem LIMIT 1;
	INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion,saesautomatico)
        VALUES(false,now(),rstockajuste.sadescripcion,CASE WHEN nullvalue(rstockajuste.saesautomatico) THEN false ELSE true END);	
	elidajuste =  currval('far_stockajuste_idstockajuste_seq');	
	elidcentroajuste = centro();
	INSERT INTO far_stockajusteestado(idstockajusteestadotipo,idstockajuste,idcentrostockajuste,eaefechaini,idusuario)
	VALUES(1,elidajuste,centro(),now(),rusuario.idusuario);
       --Lo voy a dejar en estado Creado, para que alguien lo tenga que cerrar
        INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                   ( SELECT elidajuste,pavalor as saiimporteunitario , sfc.idsigno, sfc.saicantidad
                     , pavalor * sfc.saicantidad as saiimportetotal,idarticulo,idcentroarticulo
                     ,idiva as saialicuotaiva,CASE WHEN nullvalue(pimporteiva) THEN 0 ELSE pimporteiva END * sfc.saicantidad as saiimporteiva
                     ,rusuario.idusuario as idusuario, saicantidadactual
                     from temp_far_stockajusteitem as sfc
                     natural join far_articulo
                     NATURAL JOIN far_precioarticulo
                     WHERE nullvalue(pafechafin)
                   );--saicantidadactual,saicantidad,idsigno

   respuesta = concat(elidajuste,'-',elidcentroajuste) ;     


return respuesta;

END;
$function$
