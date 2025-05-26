CREATE OR REPLACE FUNCTION public.asentarfacturaventa()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE


--registros
elem RECORD;
unitemfactura record;
tfaccupon RECORD;
regiva RECORD;
unitemfacturacosto RECORD;

--cursores
facturasventa Cursor for select * from tempfacturaventa;
facturavtacupon CURSOR FOR SELECT * FROM tempfacturaventacupon;
facturavtacc refcursor;

--variables
auxcentro integer;
importeiva Double precision;

respuesta BOOLEAN;
montocuentacorriente Double precision;
idinformefacturacion  integer;
resp BOOLEAN;
BEGIN
     respuesta = true;
   
     UPDATE  tempfacturaventa SET importeefectivo = t.importe,formapago = 2
     FROM (
          SELECT nrofactura,nrosucursal,tipocomprobante,tipofactura,sum(monto) as importe
          FROM tempfacturaventacupon
          NATURAL JOIN valorescaja
          WHERE  idformapagotipos <> 3
          GROUP BY nrofactura,nrosucursal,tipocomprobante,tipofactura
     ) as t;

     SELECT INTO montocuentacorriente  sum(monto)
     FROM tempfacturaventacupon
     NATURAL JOIN valorescaja
     WHERE  idformapagotipos = 3
     GROUP BY nrofactura,nrosucursal,tipocomprobante,tipofactura;

     UPDATE  tempfacturaventa SET importectacte = montocuentacorriente , formapago = 3 ;
     
     open  facturasventa;
     FETCH facturasventa INTO unitemfactura;

       -- Verifico si la factura genera deuda en la cuenta corriente del cliente
      if (unitemfactura.generadeuda and montocuentacorriente >0 )THEN
          --  1 - creo el informe de facturacion
          -- 2 registro la deuda
 	      -- Creo el informe de facturacion
          SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(unitemfactura.nrodoc,unitemfactura.barra,11);
          INSERT INTO cuentacorrientedeuda (
                idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                (21,unitemfactura.barra,concat(unitemfactura.nrodoc,unitemfactura.barra::varchar), now(),
                concat('Emision',unitemfactura.tipocomprobante , unitemfactura.nrosucursal::varchar
                ,unitemfactura.nrofactura::varchar),
                10311,montocuentacorriente, (idinformefacturacion*100)+Centro(),montocuentacorriente,387,unitemfactura.nrodoc,centro() );

                SELECT into resp * FROM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,'Generado desde asentarfacturaventa x deuda cliente' );
             
          UPDATE informefacturacion  SET
                 nrofactura = unitemfactura.nrofactura ,
                 tipocomprobante = unitemfactura.tipocomprobante ,
                 nrosucursal = unitemfactura.nrosucursal ,
                 idtipofactura = unitemfactura.tipofactura,
                 idformapagotipos = 3
          WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;

       END IF;



     create temp table tempfactura
      (tipocomprobante INTEGER NOT NULL,
        nrosucursal INTEGER NOT NULL,
        tipofactura VARCHAR(2),
        nrofactura BIGINT)
        WITHOUT oids;
    
     
    
    
    SELECT INTO auxcentro  centro();


    SELECT INTO elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofacturaconsucursal(auxcentro,unitemfactura.tipocomprobante,unitemfactura.tipofactura,unitemfactura.nrosucursal);

    INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura,barra)
    VALUES(unitemfactura.tipocomprobante,elem.nrosucursal,elem.nrofactura,unitemfactura.nrodoc,unitemfactura.tipodoc,1000,auxcentro,0.0,unitemfactura.importeefectivo,unitemfactura.importedebito,unitemfactura.importecredito,unitemfactura.importectacte,0,unitemfactura.fecha,
    unitemfactura.formapago,unitemfactura.tipofactura,unitemfactura.barra);

    INSERT INTO tempfactura(tipocomprobante,nrosucursal,tipofactura,nrofactura)
    VALUES(unitemfactura.tipocomprobante,elem.nrosucursal,unitemfactura.tipofactura,elem.nrofactura);




    WHILE FOUND LOOP

          INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
             VALUES(unitemfactura.tipocomprobante,elem.nrosucursal,unitemfactura.tipofactura,elem.nrofactura,unitemfactura.idconcepto,unitemfactura.cantidad,unitemfactura.importe,unitemfactura.observacion,unitemfactura.idiva);

             -- Ingreso los centros de costos
             open  facturavtacc FOR SELECT *
                        FROM tempcentrocostos 
                        WHERE idconcepto = unitemfactura.idconcepto
                        AND iditem = unitemfactura.iditem;
             FETCH facturavtacc INTO unitemfacturacosto;
             WHILE FOUND LOOP

                   INSERT INTO itemfacturaventacentroscosto (nrosucursal,nrofactura,iditem,tipocomprobante,tipofactura,idcentrocosto,monto)
                   VALUES(unitemfacturacosto.nrosucursal,unitemfacturacosto.nrofactura,currval('itemfacturaventa_iditem_seq'),unitemfacturacosto.tipocomprobante,unitemfacturacosto.tipofactura,unitemfacturacosto.idcentrocosto,unitemfacturacosto.importe);

                   FETCH facturavtacc INTO unitemfacturacosto;
             END LOOP;
             CLOSE facturavtacc;

     FETCH facturasventa INTO unitemfactura;
     END LOOP;
     CLOSE facturasventa;


     --vinculo la factura con la/s forma/s de pago
     open facturavtacupon;
     FETCH facturavtacupon into tfaccupon;
           WHILE FOUND LOOP
                 INSERT INTO facturaventacupon(nrofactura, tipocomprobante, nrosucursal,
                 tipofactura, idvalorescaja, autorizacion, nrotarjeta, monto,
                 cuotas, nrocupon)
                 VALUES(tfaccupon.nrofactura, tfaccupon.tipocomprobante, elem.nrosucursal, tfaccupon.tipofactura,
                 tfaccupon.idvalorescaja, tfaccupon.autorizacion, tfaccupon.nrotarjeta,tfaccupon.monto,
                 tfaccupon.cuotas, tfaccupon.nrocupon);
           FETCH facturavtacupon into tfaccupon;
           END LOOP;
     close facturavtacupon;


   
          

     return respuesta;
end;
$function$
