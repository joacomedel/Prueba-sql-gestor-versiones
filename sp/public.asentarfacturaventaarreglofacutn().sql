CREATE OR REPLACE FUNCTION public.asentarfacturaventaarreglofacutn()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

elem RECORD;
facturasventa Cursor for select * from tempfacturaventa;
unitemfactura record;
auxcentro integer;
facturavtacupon CURSOR FOR SELECT * FROM tempfacturaventacupon;
tfaccupon RECORD;






BEGIN


open  facturasventa;


FETCH facturasventa INTO unitemfactura;
create temp table tempfactura
      (tipocomprobante INTEGER NOT NULL,
		nrosucursal INTEGER NOT NULL,
		tipofactura VARCHAR(2),
		nrofactura BIGINT)
        WITHOUT oids;
	
--SELECT INTO auxcentro  centro();

auxcentro = 12; --es el idcentroregional de plaza huincul (UTN)

SELECT INTO elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(auxcentro,unitemfactura.tipocomprobante,unitemfactura.tipofactura);

INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura,barra)
VALUES(unitemfactura.tipocomprobante,elem.nrosucursal,unitemfactura.nrofactura,unitemfactura.nrodoc,unitemfactura.tipodoc,1000,auxcentro,0.0,unitemfactura.importeefectivo,unitemfactura.importedebito,unitemfactura.importecredito,unitemfactura.importectacte,0,unitemfactura.fecha,unitemfactura.formapago,unitemfactura.tipofactura,unitemfactura.barra);

INSERT INTO tempfactura(tipocomprobante,nrosucursal,tipofactura,nrofactura)
   VALUES(unitemfactura.tipocomprobante,elem.nrosucursal,unitemfactura.tipofactura,unitemfactura.nrofactura);

--FETCH facturasventa INTO unitemfactura;

WHILE FOUND LOOP

INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
   VALUES(unitemfactura.tipocomprobante,elem.nrosucursal,unitemfactura.tipofactura,unitemfactura.nrofactura,unitemfactura.idconcepto,unitemfactura.cantidad,unitemfactura.importe,unitemfactura.observacion,1);


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


return true;
end;
$function$
