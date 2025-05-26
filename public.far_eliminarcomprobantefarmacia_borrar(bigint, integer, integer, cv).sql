CREATE OR REPLACE FUNCTION public.far_eliminarcomprobantefarmacia_borrar(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       ptipocomprobante integer;
       pnrosucursal integer;
       pnrofactura bigint;
       ptipofactura varchar ;

       cfar_ordenventa refcursor;
       rfar_ordenventa record;
       resp boolean;

       elidajuste integer;
       ritemfacturaventa record;
       cfar_ordenventaorden refcursor;
       rfar_ordenventaorden record;
BEGIN
  -- Antes que nada verifico que existan todas las FK que deben existir para garantizar la robustez y buen funcionamiento del SP
        SELECT INTO resp * FROM existefkey();
        IF (not resp) THEN return false; END IF ;

     pnrofactura  =$1;
     pnrosucursal =$2;
     ptipocomprobante =$3;
     ptipofactura  =$4;

   /* Revertir el stock si se trata de una NC
    IF (ptipofactura = 'NC') THEN
                     INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('GA - Reversion del Comprobante :',ptipofactura,' ',pnrofactura,'/',pnrosucursal));

                     elidajuste =  currval('far_stockajuste_idstockajuste_seq');

                     INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                     VALUES(5,elidajuste,centro(),now());

                     SELECT into ritemfacturaventa *
                     FROM itemfacturaventa
                     join far_ordenventaitemitemfacturaventa using(nrofactura,tipofactura,tipocomprobante,nrosucursal)
                     join far_ordenventaitem USING (idordenventaitem ,idcentroordenventaitem)
                     WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
                           and nrosucursal=pnrosucursal;
    
                     INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                     VALUES(elidajuste, (ritemfacturaventa.importe /ritemfacturaventa.cantidad), +1 ,
                           ritemfacturaventa.cantidad, ritemfacturaventa.importe ,ritemfacturaventa.idarticulo
                           ,ritemfacturaventa.idcentroarticulo,ritemfacturaventa.oviimporteiva,ritemfacturaventa.oviimporteiva,
                           25,far_darcantidadarticulostock(ritemfacturaventa.idarticulo,ritemfacturaventa.idcentroarticulo) );
    
    
    
                     CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
                     INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Eliminacion comprobante x error fact. ',elidajuste,'-',centro()) ,1);
                     SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);
                     
                     
                     DELETE FROM far_movimientostockitemfactventa
                     WHERE  nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
                         and nrosucursal=pnrosucursal;
                     
    END IF;*/

    /* Las ordenes de venta se dejan en estado 1 = emitida asi pueden volver a facturarse
    OPEN cfar_ordenventaorden FOR
          SELECT * FROM facturaorden
          WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
          and nrosucursal=pnrosucursal;

     FETCH cfar_ordenventaorden into rfar_ordenventaorden;
     WHILE FOUND LOOP
             PERFORM far_cambiarestadoordenventa( rfar_ordenventaorden.nroorden,rfar_ordenventaorden.centro,1);
             FETCH cfar_ordenventaorden into rfar_ordenventaorden;
     END LOOP;
     */
     /* Se elimina toda la estructura de factura*/
    DELETE FROM facturaorden WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM facturaventacupon WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM itemfacturaventa WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

   DELETE FROM facturaventanofiscal WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;



    DELETE FROM far_ordenventaitemitemfacturaventa WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;
    
    DELETE from facturaventausuario WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante and nrosucursal=pnrosucursal;

    DELETE FROM facturaventa WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;


  /* DELETE FROM far_movimientostockitemfactventa
                     WHERE  nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
                         and nrosucursal=pnrosucursal;*/
    
return 'true';
END;

$function$
