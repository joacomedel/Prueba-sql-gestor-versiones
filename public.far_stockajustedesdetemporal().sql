CREATE OR REPLACE FUNCTION public.far_stockajustedesdetemporal()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    elidajuste  integer;
    respuesta varchar;
    rusuario record;
    rtemp record;
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

       SELECT INTO rtemp * FROM temp_stockfarmacia WHERE operacion = 'determinar';
       IF FOUND THEN --Malapi 06-01-2014 si la operacion es determinar, hay que determinar el signo y la operacion. 
           UPDATE temp_stockfarmacia SET cantidadvista = 0,cantidadajustada = t.diferencia,idsigno = t.idsigno 
            FROM (
                 select abs(cantidadvista - cantidadajustada) as diferencia,
                 case when (cantidadvista - cantidadajustada) > 0 then -1 else 1 end as idsigno,
                 idarticulo,idcentroarticulo
                 from temp_stockfarmacia
             ) as t
             WHERE t.idarticulo = temp_stockfarmacia.idarticulo 
                 AND t.idcentroarticulo = temp_stockfarmacia.idcentroarticulo;
       END IF;

       respuesta = '';

      --Genero el Comprobante de Ingreso
      INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion)
        (SELECT false, now(),concat('GA - \n Motivo del Usuario: \n',
		temp_stockfarmacia.descripcionstockajuste , ' ' , '\n') as motivo
       from temp_stockfarmacia
       natural join far_articulo
       limit 1
       );
       SELECT INTO rtemp * FROM temp_stockfarmacia ;
       IF FOUND THEN 
           elidajuste =  currval('far_stockajuste_idstockajuste_seq');
           respuesta = concat(respuesta , elidajuste,'-',centro() , '|');
           INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
       VALUES(1,elidajuste,centro(),now());
       --Lo voy a dejar en estado Creado, para que alguien lo tenga que cerrar

           INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                   ( SELECT elidajuste,pavalor as saiimporteunitario , sfc.idsigno, sfc.cantidadajustada as saicantidad
                     , pavalor * sfc.cantidadajustada as saiimportetotal,idarticulo,idcentroarticulo
                     ,idiva as saialicuotaiva,CASE WHEN nullvalue(pimporteiva) THEN 0 ELSE pimporteiva END * sfc.cantidadajustada as saiimporteiva
                     ,rusuario.idusuario as idusuario,far_darcantidadarticulostock(idarticulo,idcentroarticulo) AS saicantidadactual
                     from (select idarticulo,idcentroarticulo,idsigno
                          ,sum(CASE WHEN not nullvalue(cantidadajustada) THEN cantidadajustada ELSE 0 END) as cantidadajustada
			  from temp_stockfarmacia
                          GROUP BY idarticulo,idcentroarticulo,idsigno
                          ) as sfc
                     natural join far_articulo
                     NATURAL JOIN far_precioarticulo
                     WHERE nullvalue(pafechafin)
                   );

       END IF;

       


return respuesta;

END;
$function$
