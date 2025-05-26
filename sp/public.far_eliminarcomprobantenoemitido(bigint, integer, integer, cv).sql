CREATE OR REPLACE FUNCTION public.far_eliminarcomprobantenoemitido(bigint, integer, integer, character varying)
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
       respuestaeliminar boolean;

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

   /* Revertir el stock si se trata de una NC*/
    IF (ptipofactura = 'NC') THEN


SELECT into ritemfacturaventa *
                     FROM itemfacturaventa
                     join far_ordenventaitemitemfacturaventa using(nrofactura,tipofactura,tipocomprobante,nrosucursal)
                     join far_ordenventaitem USING (idordenventaitem ,idcentroordenventaitem)
                     WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
                           and nrosucursal=pnrosucursal;
IF FOUND THEN
                      INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('GA - Reversion del Comprobante :',ptipofactura,' ',pnrofactura,'/',pnrosucursal));

                     elidajuste =  currval('far_stockajuste_idstockajuste_seq');

                     INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                     VALUES(5,elidajuste,centro(),now());

                     

                     INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,
                     idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                     VALUES(elidajuste, (ritemfacturaventa.importe /ritemfacturaventa.cantidad), +1 ,
                           ritemfacturaventa.cantidad, ritemfacturaventa.importe ,ritemfacturaventa.idarticulo
                           ,ritemfacturaventa.idcentroarticulo,ritemfacturaventa.idiva,ritemfacturaventa.oviimporteiva,25,
                           far_darcantidadarticulostock(ritemfacturaventa.idarticulo,ritemfacturaventa.idcentroarticulo) );



                     CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
                     INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Eliminacion comprobante x error fact. ',elidajuste,'-',centro()) ,1);
                     SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);
                     
                     DELETE FROM far_movimientostockitemfactventa
                     WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura
                           and tipocomprobante =ptipocomprobante     and nrosucursal=pnrosucursal;
END IF;
    END IF;

    /* Las ordenes de venta se dejan en estado 1 = emitida asi pueden volver a facturarse
       siempre y cuando no esten facturadas en alguna otra orden
    */
    OPEN cfar_ordenventaorden FOR
          SELECT * FROM facturaorden
          WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
          and nrosucursal=pnrosucursal
          and (centro ,nroorden) NOT IN
              (SELECT centro ,nroorden
               FROM facturaorden
               WHERE nrofactura <> pnrofactura and (nrosucursal =4 or nrosucursal =2 or nrosucursal=18 or nrosucursal=20) )
          ;

     FETCH cfar_ordenventaorden into rfar_ordenventaorden;
     WHILE FOUND LOOP
             IF rfar_ordenventaorden.idcomprobantetipos	= 44 THEN
                PERFORM far_cambiarestadoordenventa(rfar_ordenventaorden.nroorden,rfar_ordenventaorden.centro,1);
             ELSE 
                PERFORM expendio_cambiarestadoorden(rfar_ordenventaorden.nroorden,rfar_ordenventaorden.centro,1);
             END IF;
             FETCH cfar_ordenventaorden into rfar_ordenventaorden;
     END LOOP;

     /* Se elimina toda la estructura de factura*/
DELETE FROM controlcajafacturaventa WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM facturaorden WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

DELETE FROM facturaventacuponlote WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM facturaventacupon WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM itemfacturaventa WHERE nrofactura =pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

DELETE FROM facturaventausuario WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante and nrosucursal=pnrosucursal;

DELETE FROM far_ordenventaitemitemfacturaventa WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante and nrosucursal=pnrosucursal;

DELETE FROM facturaventanofiscal WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

DELETE FROM facturaventa_wsafip WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

 DELETE FROM contabilidad_periodofiscalfacturaventa WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;


    DELETE FROM facturaventa WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

---------- Elimino del esquema sincro
   
    DELETE FROM sincro.facturaorden WHERE nrofactura >=pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
                 and nrosucursal=pnrosucursal;

    DELETE FROM sincro.facturaventacuponlote WHERE nrofactura >=pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
           and nrosucursal=pnrosucursal;

    DELETE FROM sincro.facturaventacupon WHERE nrofactura >=pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM sincro.itemfacturaventa WHERE nrofactura >=pnrofactura   and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM sincro.facturaventausuario WHERE nrofactura >=pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante and nrosucursal=pnrosucursal;

    DELETE FROM sincro.far_ordenventaitemitemfacturaventa WHERE nrofactura >=pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante and nrosucursal=pnrosucursal;

    DELETE FROM sincro.facturaventanofiscal WHERE nrofactura >=pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

    DELETE FROM sincro.contabilidad_periodofiscalfacturaventa WHERE nrofactura >=pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;


    DELETE FROM sincro.facturaventa WHERE nrofactura >=pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
    and nrosucursal=pnrosucursal;

return 'true';
END;
$function$
