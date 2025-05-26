CREATE OR REPLACE FUNCTION public.far_reemitircomprobantenoemitido(bigint, integer, integer, character varying, integer, bigint)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
ptipocomprobante integer;
pnrosucursal integer;
pnrofactura bigint;
elidusuario bigint;
ptipofactura varchar ;
pnrosucimpresor integer;
eliditem bigint;
cfar_ordenventa refcursor;

cfar_ovitem_fvitem  refcursor;

rfar_ordenventa record;
rfar_ovitem_fvitem record;
rrecibo record;
elem record;
elcomprobante varchar;

BEGIN


     pnrofactura  =$1;
     pnrosucursal =$2;
     ptipocomprobante =$3;
     ptipofactura  =$4;

      pnrosucimpresor  =$5;
      elidusuario  =$6;
     --------- Anulo el comprobante que se va a reemitir
   /*  UPDATE facturaventa
     SET anulada=now()
     WHERE  tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura ;
*/
     SELECT into elem *
     FROM devolvernrofactura(centro(),ptipocomprobante,ptipofactura,pnrosucimpresor);

     INSERT INTO facturaventa
     (tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,fechaemision,tipofactura,barra,
     importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc)
      (   SELECT tipocomprobante , elem.nrosucursal , elem.sgtenumero , nrodoc,tipodoc,ctacontable,centro,now(),ptipofactura,barra,
      importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc
         FROM facturaventa
         WHERE  tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura
     );

     elcomprobante = concat(elem.tipocomprobante,'|',elem.tipofactura,'|',elem.nrosucursal,'|',elem.sgtenumero);

  /* Se vincula las ordenes a la factura generadas*/

   INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,  nrofactura, nroorden, centro, idcomprobantetipos)
   (
    SELECT tipocomprobante,elem.nrosucursal,tipofactura,   elem.sgtenumero , nroorden, centro, idcomprobantetipos
    FROM facturaorden
    WHERE tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura
   );

    /** Vuelvo las ordenes a pendientes de facturacion */

     OPEN cfar_ordenventa FOR
          SELECT * FROM facturaorden
          WHERE nrofactura =pnrofactura  and tipofactura=ptipofactura and tipocomprobante =ptipocomprobante
                 and nrosucursal=pnrosucursal;
/* VOLVER A COMENTAR !!
     FETCH cfar_ordenventa into rfar_ordenventa;
     WHILE FOUND LOOP
            PERFORM far_cambiarestadoordenventa( rfar_ordenventa.nroorden,rfar_ordenventa.centro,1);
            FETCH cfar_ordenventa into rfar_ordenventa;
     END LOOP;

     CLOSE cfar_ordenventa;
*/

     OPEN cfar_ovitem_fvitem FOR
          SELECT * FROM itemfacturaventa
          LEFT JOIN  far_ordenventaitemitemfacturaventa using (iditem,nrofactura,nrosucursal,tipofactura,tipocomprobante)
          WHERE tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                nrosucursal=pnrosucursal and  nrofactura = pnrofactura ;

     FETCH cfar_ovitem_fvitem into rfar_ovitem_fvitem;
     WHILE FOUND LOOP
             INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura, nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
             VALUES ( rfar_ovitem_fvitem.tipocomprobante,elem.nrosucursal,rfar_ovitem_fvitem.tipofactura, elem.sgtenumero ,rfar_ovitem_fvitem.idconcepto,rfar_ovitem_fvitem.cantidad,rfar_ovitem_fvitem.importe,rfar_ovitem_fvitem.descripcion,rfar_ovitem_fvitem.idiva    );

             eliditem = currval('itemfacturaventa_iditem_seq');
             IF(not nullvalue(rfar_ovitem_fvitem.idordenventaitem)) THEN
                  INSERT INTO far_ordenventaitemitemfacturaventa (idordenventaitem,idcentroordenventaitem, iditem,nrofactura,nrosucursal,tipocomprobante,tipofactura)
                  VALUES (rfar_ovitem_fvitem.idordenventaitem,rfar_ovitem_fvitem.idcentroordenventaitem,
                     eliditem,  elem.sgtenumero,elem.nrosucursal,rfar_ovitem_fvitem.tipocomprobante,rfar_ovitem_fvitem.tipofactura);
             END IF;
             FETCH cfar_ovitem_fvitem into rfar_ovitem_fvitem;
     END LOOP;
     CLOSE cfar_ovitem_fvitem;

     /*  GUARDAN LOS CUPONES */

      INSERT INTO facturaventacupon (nrofactura, tipocomprobante, nrosucursal, tipofactura,
             idvalorescaja,   monto,nrocupon, nrotarjeta, cuotas , autorizacion)
      (SELECT  elem.sgtenumero, tipocomprobante, elem.nrosucursal, tipofactura,
             idvalorescaja,   monto,nrocupon, nrotarjeta, cuotas , autorizacion
       FROM facturaventacupon
       WHERE
               tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
               nrosucursal=pnrosucursal and  nrofactura = pnrofactura
         );
         /*Recupero info del emisor del comprobante*/

         INSERT INTO facturaventausuario (tipocomprobante,nrosucursal,nrofactura,tipofactura,idusuario)
         VALUES ( elem.tipocomprobante, elem.nrosucursal, elem.sgtenumero,elem.tipofactura, elidusuario );
         IF (pnrosucursal=1001) THEN
                SELECT INTO rrecibo * 
                FROM facturaorden
                NATURAL JOIN ordenrecibo
                WHERE tipofactura = ptipofactura and tipocomprobante = ptipocomprobante and
                       nrosucursal=pnrosucursal and  nrofactura = pnrofactura
                limit 1;
                INSERT INTO facturaventa_wsafip(tipocomprobante,nrosucursal,nrofactura,tipofactura,idrecibo,centro)     VALUES(elem.tipocomprobante,elem.nrosucursal,elem.sgtenumero,elem.tipofactura,rrecibo.idrecibo,rrecibo.centro);
         END IF;
return elcomprobante;
END;
$function$
