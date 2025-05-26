CREATE OR REPLACE FUNCTION public.asentarfacturaventaversion2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
elem RECORD;
esbeneficiario RECORD;
nrodocumento VARCHAR;
tdoc INTEGER;
barra1 INTEGER;

ordenespendientes CURSOR FOR SELECT * FROM tempordenespendientes;
torden RECORD;

items CURSOR FOR SELECT * FROM tempitemsordenespendientes;
itemf RECORD;

facturaordenes CURSOR FOR SELECT * FROM tempfacturaorden;
itemo RECORD;

facturavtacupon CURSOR FOR SELECT * FROM tempfacturaventacupon;
tfaccupon RECORD;


BEGIN


open ordenespendientes;
FETCH ordenespendientes into torden;

SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(torden.centro,torden.tipocomprobante,torden.tipofactura);

      SELECT INTO esbeneficiario nrodoctitu,tipodoctitu from benefsosunc
      where (benefsosunc.nrodoc = torden.nrodoc and benefsosunc.tipodoc=torden.tipodoc);
      if found  then
          nrodocumento=esbeneficiario.nrodoctitu;
          tdoc=esbeneficiario.tipodoctitu;
      else
          nrodocumento=torden.nrodoc;
          tdoc = torden.tipodoc;

      END IF;

      SELECT INTO barra1 barra FROM persona
      WHERE (nrodoc = nrodocumento AND tipodoc = tdoc);

      INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago,tipofactura,barra)
      VALUES(torden.tipocomprobante,elem.nrosucursal,elem.nrofactura,nrodocumento,tdoc,1000,torden.centro,torden.importeamuc,torden.importeefectivo,torden.importedebito,torden.importecredito,torden.importectacte,torden.importesosunc,torden.fechaemision,torden.formapago,torden.tipofactura,barra1);

   --   UPDATE talonario SET sgtenumero=sgtenumero+1 where talonario.centro=torden.centro and talonario.tipocomprobante = torden.tipocomprobante and talonario.tipofactura = torden.tipofactura;

CLOSE ordenespendientes;

open items;
FETCH items into itemf;
      WHILE FOUND LOOP
            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
            VALUES(itemf.tipocomprobante,elem.nrosucursal,itemf.tipofactura,elem.nrofactura,itemf.idconcepto,itemf.cantidad,itemf.importe,itemf.descripcion,1);
        FETCH items into itemf;
        END LOOP;
close items;


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

open facturaordenes;
FETCH facturaordenes into itemo;
      WHILE FOUND LOOP
            INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,nrofactura,nroorden,centro)
            VALUES(itemo.tipocomprobante,elem.nrosucursal,itemo.tipofactura,elem.nrofactura,itemo.nroorden,itemo.centro);
      FETCH facturaordenes into itemo;
      END LOOP;
CLOSE facturaordenes;

return true;
END;
$function$
