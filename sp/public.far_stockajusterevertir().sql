CREATE OR REPLACE FUNCTION public.far_stockajusterevertir()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
     elidajuste  integer;
     cstockajuste CURSOR FOR SELECT *
                FROM temstockajuste;
     rstockajuste record;
     resp boolean;
     rusuario record;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

    OPEN cstockajuste;
    FETCH cstockajuste into rstockajuste;
    WHILE  found LOOP
           INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion)
                  (SELECT false, now(), concat('GA - Reversion del Comprobante :',rstockajuste.idstockajuste ,'/', rstockajuste.idcentrostockajuste ,' ','. Motivo del Usuario: ',rstockajuste.comentario)
                   FROM far_stockajuste
                   WHERE idcentrostockajuste = rstockajuste.idcentrostockajuste
                           and idstockajuste = rstockajuste.idstockajuste );
           elidajuste =  currval('far_stockajuste_idstockajuste_seq');

           INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                  VALUES(5,elidajuste,centro(),now());

           INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                   ( SELECT elidajuste, saiimporteunitario, (idsigno * -1 ), saicantidad, saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,rusuario.idusuario,far_darcantidadarticulostock(idarticulo,idcentroarticulo) AS saicantidadactual
                     FROM far_stockajusteitem
                     WHERE idcentrostockajuste = rstockajuste.idcentrostockajuste
                           and idstockajuste = rstockajuste.idstockajuste
                   );

           FETCH cstockajuste into rstockajuste;
    END LOOP;
    close cstockajuste;
    CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
    INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Reversion de stock ajuste ', elidajuste,'-',centro()) ,1);
    SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);


    return concat(elidajuste,'-',centro()) ;
    
END;
$function$
