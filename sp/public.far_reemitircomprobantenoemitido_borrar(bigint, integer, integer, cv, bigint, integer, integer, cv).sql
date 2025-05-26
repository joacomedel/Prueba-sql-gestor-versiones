CREATE OR REPLACE FUNCTION public.far_reemitircomprobantenoemitido_borrar(bigint, integer, integer, character varying, bigint, integer, integer, character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

ptipocomprobante integer;
pnrosucursal integer;
pnrofactura bigint;
ptipofactura varchar ;

pdtipocomprobante integer;
pdnrosucursal integer;
pdnrofactura bigint;
pdtipofactura varchar ;
rrecibo record;


eliditem bigint;
cfar_ovitem_fvitem  refcursor;

rtalonario record;

rfar_ovitem_fvitem record;


elcomprobante varchar;

BEGIN
--select  * from far_reemitircomprobantenoemitido_borrar(96810,20,1,'FA',701,2,1,'NC')



     -- Info de la factura que se quiere reemitir ( ORIGEN)
     pnrofactura  =$1;
     pnrosucursal =$2;
     ptipocomprobante =$3;
     ptipofactura  =$4;

     -- Info de la factura en la que se desea poner los datos (DESTINO)
     pdnrofactura  =$5;
     pdnrosucursal =$6;
     pdtipocomprobante =$7;
     pdtipofactura  =$8;


     -- Si los datos de la factura destino son NULL es x que se desea utilizar el talonario
     if (nullvalue (pdnrofactura) OR pdnrofactura = 0 ) THEN
          /*SELECT INTO rtalonario *
          FROM talonario
          WHERE nrosucursal = pdnrosucursal
                and tipofactura = pdtipofactura
                and tipocomprobante= ptipocomprobante;
          */

          SELECT into rtalonario *
             FROM devolvernrofactura(centro(),pdtipocomprobante,pdtipofactura,pdnrosucursal); 

          pdnrofactura  = rtalonario.sgtenumero;
          pdnrosucursal = rtalonario.nrosucursal;
          pdtipocomprobante = rtalonario.tipocomprobante;
          pdtipofactura  = rtalonario.tipofactura;

     END IF;

     elcomprobante = concat(pdnrosucursal,'-',pdtipofactura , '-',pdnrofactura);

     INSERT INTO facturaventa
     (tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra,importeefectivo
,importectacte)
      (  SELECT pdtipocomprobante , pdnrosucursal , pdnrofactura , nrodoc,tipodoc,ctacontable,centro,fechaemision,pdtipofactura,barra,importeefectivo,importectacte
         FROM facturaventa
         WHERE  tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura
     );

   

 --- Se vincula las ordenes a la factura generadas

   INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,  nrofactura, nroorden, centro, idcomprobantetipos)
   (
    SELECT pdtipocomprobante,pdnrosucursal,pdtipofactura,pdnrofactura, nroorden, centro, idcomprobantetipos
    FROM facturaorden
    WHERE tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura
   );

     OPEN cfar_ovitem_fvitem FOR
          SELECT * FROM itemfacturaventa
          LEFT JOIN  far_ordenventaitemitemfacturaventa using (iditem,nrofactura,nrosucursal,tipofactura,tipocomprobante)
          WHERE tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal = pnrosucursal and  nrofactura = pnrofactura;

     FETCH cfar_ovitem_fvitem into rfar_ovitem_fvitem;
     WHILE FOUND LOOP
             INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura, nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
             VALUES (pdtipocomprobante  ,pdnrosucursal,pdtipofactura, pdnrofactura ,rfar_ovitem_fvitem.idconcepto,rfar_ovitem_fvitem.cantidad,rfar_ovitem_fvitem.importe,rfar_ovitem_fvitem.descripcion,rfar_ovitem_fvitem.idiva    );

             eliditem = currval('itemfacturaventa_iditem_seq');
            IF(not nullvalue(rfar_ovitem_fvitem.idordenventaitem)) THEN
                  INSERT INTO far_ordenventaitemitemfacturaventa (idordenventaitem,idcentroordenventaitem, iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura)
                  VALUES (rfar_ovitem_fvitem.idordenventaitem,rfar_ovitem_fvitem.idcentroordenventaitem,
                     eliditem,  pdnrofactura,pdnrosucursal,pdtipocomprobante,pdtipofactura);
             END IF;
             FETCH cfar_ovitem_fvitem into rfar_ovitem_fvitem;
     END LOOP;
     CLOSE cfar_ovitem_fvitem;

     /*  GUARDAN LOS CUPONES */

      INSERT INTO facturaventacupon (nrofactura, tipocomprobante, nrosucursal, tipofactura,centro,
             idvalorescaja,   monto,nrocupon, nrotarjeta, cuotas , autorizacion)
      (SELECT  pdnrofactura, pdtipocomprobante, pdnrosucursal, pdtipofactura,centro,
             idvalorescaja,   monto,nrocupon, nrotarjeta, cuotas , autorizacion
       FROM facturaventacupon
       WHERE
             tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura
         );

   --- Se guardan la info del usuario que emitio el comprobante
       INSERT INTO facturaventausuario (tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario,nrofacturafiscal)
               (SELECT pdtipocomprobante,pdnrosucursal,pdnrofactura,pdtipofactura,idusuario,pdnrofactura
                FROM facturaventausuario
                WHERE
                     tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                     nrosucursal=pnrosucursal and  nrofactura = pnrofactura );
 IF (pnrosucursal=1001) THEN
                SELECT INTO rrecibo * 
                FROM facturaorden
                NATURAL JOIN ordenrecibo
                WHERE tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                       nrosucursal=pnrosucursal and  nrofactura = pnrofactura
                limit 1;
                INSERT INTO facturaventa_wsafip(tipocomprobante,nrosucursal,nrofactura,tipofactura,idrecibo,centro)     VALUES(pdtipocomprobante,pdnrosucursal,pdnrofactura,pdtipofactura,rrecibo.idrecibo,rrecibo.centro);
         END IF;
return elcomprobante;
END;
$function$
