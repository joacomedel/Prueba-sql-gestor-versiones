CREATE OR REPLACE FUNCTION public.far_stockajusteparacopahue()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    elidajuste  integer;
    respuesta varchar;
BEGIN

       respuesta = '';

      --Genero el Comprobante de Ingreso
      INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion)
        (SELECT false, now(),concat('GA - Ingreso Productos sobrantes de Copahue. Este comprabonate de Ajuste se Genero usando una planilla cargada por Luciana Rubilar
        \n Motivo del Usuario: \n',
        text_concatenar(concat(' * ' ,stockfarmaciacopahue.acodigobarra
       , ' ' ,stockfarmaciacopahue.descripcion
       , ' ' , observacionmotivodescarte
       , ' ' , '\n')
       )) as motivo
       from stockfarmaciacopahue
       natural join far_articulo
       WHERE not nullvalue(stockfarmaciacopahue.observacionmotivodescarte)
       );
       elidajuste =  currval('far_stockajuste_idstockajuste_seq');
       respuesta = concat(respuesta , elidajuste,'-',centro() , '|');

           INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                  VALUES(1,elidajuste,centro(),now());
           --Lo voy a dejar en estado Creado, para que alguien lo tenga que cerrar

           INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                   ( SELECT elidajuste,pavalor as saiimporteunitario , 1 as idsigno, cantidadparamostrador as saicantidad
                     , pavalor * cantidadparamostrador as saiimportetotal,idarticulo,idcentroarticulo
                     ,idiva as saialicuotaiva,CASE WHEN nullvalue(pimporteiva) THEN 0 ELSE pimporteiva END * cantidadparamostrador as saiimporteiva
                     ,25 as idusuario,far_darcantidadarticulostock(idarticulo,idcentroarticulo) AS saicantidadactual
                     from (select idarticulo
                          ,sum(CASE WHEN not nullvalue(cantidadcontada) THEN cantidadcontada ELSE 0 END)
                          ,sum(CASE WHEN not nullvalue(cantidadparamostrador) THEN cantidadparamostrador ELSE cantidadcontada END) as cantidadparamostrador
                          ,sum(CASE WHEN not nullvalue(cantidadsedescarta) THEN cantidadsedescarta ELSE 0 END)
                          from stockfarmaciacopahue
                          GROUP BY idarticulo
                          ) as sfc
                     natural join far_articulo
                     NATURAL JOIN far_precioarticulo
                     WHERE nullvalue(pafechafin)
                   );


--Genero el Comprobante de Salida
      INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion)
        (SELECT false, now(),concat('GA - Descarte de productos sobrantes de Copahue. Este comprabonate de Ajuste se Genero usando una planilla cargada por Luciana Rubilar
        \n Motivo del Usuario: \n',
        text_concatenar(concat(' * ' ,stockfarmaciacopahue.acodigobarra
       , ' ' ,stockfarmaciacopahue.descripcion
       , ' ' , observacionmotivodescarte
       , ' ' ,'\n')
       )) as motivo
       from stockfarmaciacopahue
       natural join far_articulo
       NATURAL JOIN (select idarticulo
                        ,sum(CASE WHEN not nullvalue(cantidadcontada) THEN cantidadcontada ELSE 0 END) as cantidadcontada
                        ,sum(CASE WHEN not nullvalue(cantidadparamostrador) THEN cantidadparamostrador ELSE cantidadcontada END) as cantidadparamostrador
                        ,sum(CASE WHEN not nullvalue(cantidadsedescarta) THEN cantidadsedescarta ELSE 0 END) as cantidadsedescarta
                        from stockfarmaciacopahue
                        GROUP BY idarticulo
                        ) as sfc
       WHERE not nullvalue(stockfarmaciacopahue.observacionmotivodescarte) AND cantidadsedescarta > 0
       );
           elidajuste =  currval('far_stockajuste_idstockajuste_seq');
           respuesta = concat(respuesta,elidajuste,'-',centro() , '|');

           INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                  VALUES(1,elidajuste,centro(),now()); --Lo voy a dejar en estado Creado, para que alguien lo tenga que cerrar

           INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                   ( SELECT elidajuste,pavalor as saiimporteunitario , -1 as idsigno, cantidadsedescarta as saicantidad
                   , pavalor * cantidadsedescarta as saiimportetotal,idarticulo,idcentroarticulo
                   ,idiva as saialicuotaiva,CASE WHEN nullvalue(pimporteiva) THEN 0 ELSE pimporteiva END * cantidadsedescarta as saiimporteiva
                   ,25 as idusuario,far_darcantidadarticulostock(idarticulo,idcentroarticulo) AS saicantidadactual
                   from (select idarticulo
                        ,sum(CASE WHEN not nullvalue(cantidadcontada) THEN cantidadcontada ELSE 0 END) as cantidadcontada
                        ,sum(CASE WHEN not nullvalue(cantidadparamostrador) THEN cantidadparamostrador ELSE cantidadcontada END) as cantidadparamostrador
                        ,sum(CASE WHEN not nullvalue(cantidadsedescarta) THEN cantidadsedescarta ELSE 0 END) as cantidadsedescarta
                        from stockfarmaciacopahue
                        GROUP BY idarticulo
                        ) as sfc
                   natural join far_articulo
                   NATURAL JOIN far_precioarticulo
                   WHERE nullvalue(pafechafin)
                         AND cantidadsedescarta > 0
                   );

return respuesta;

END;
$function$
