CREATE OR REPLACE FUNCTION public.asentarfacturaaportesjubpen(tipoc integer, tipof character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
elem RECORD;
aportesjubpen Cursor for select * from tempaportejubpen;
unaportejubpen record;
asientosjubpen Cursor for select * from tempasiento;
unasientojubpen record;
tdoc smallint;
BEGIN


open aportesjubpen;
fetch aportesjubpen into unaportejubpen;
open asientosjubpen;
FETCH asientosjubpen INTO unasientojubpen;

SELECT into tdoc tipodoc FROM persona WHERE nrodoc = unaportejubpen.nrodoc;

CREATE TEMP TABLE ttfacturasgeneradas
(
   nrosucursal integer,
   nrofactura bigint,
   mes integer,
   anio integer,
   nrodoc varchar,
   tipodoc smallint,
   centro integer,
   tipocomprobante integer,
   tipofactura varchar(2)
) WITHOUT OIDS;

SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(unasientojubpen.centro,tipoc,tipof);

INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura)
VALUES(tipoc,elem.nrosucursal,elem.nrofactura,unaportejubpen.nrodoc,tdoc,1000,unasientojubpen.centro,unasientojubpen.amuc,unasientojubpen.efectivo,unasientojubpen.debito,unasientojubpen.credito,unasientojubpen.cuentacorriente,0,current_date,2,tipof);

INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
   VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,'50340',1,unaportejubpen.importe,concat('Aporte mes: ',unaportejubpen.mes,' Año: ',unaportejubpen.anio),1);


  INSERT INTO ttfacturasgeneradas (nrosucursal,tipofactura,nrofactura,mes,anio,nrodoc,tipodoc,centro,tipocomprobante)
         VALUES (elem.nrosucursal,tipof,elem.nrofactura,unaportejubpen.mes,unaportejubpen.anio,unaportejubpen.nrodoc,tdoc,unasientojubpen.centro,tipoc);

FETCH aportesjubpen INTO unaportejubpen;
      WHILE FOUND LOOP
         INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
         VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,'50340',1,unaportejubpen.importe,concat('Aporte mes: ',unaportejubpen.mes,' Año: ',unaportejubpen.anio),1);

         INSERT INTO ttfacturasgeneradas (nrosucursal,tipofactura,nrofactura,mes,anio,nrodoc,tipodoc,centro,tipocomprobante)
         VALUES (elem.nrosucursal,tipof,elem.nrofactura,unaportejubpen.mes,unaportejubpen.anio,unaportejubpen.nrodoc,tdoc,unasientojubpen.centro,tipoc);

         FETCH aportesjubpen INTO unaportejubpen;

      END LOOP;
      CLOSE aportesjubpen;

 --  inserta las facturas en ttfacturasgeneradas

 INSERT INTO facturaaporte(nrosucursal,tipofactura,nrofactura,mes,anio,nrodoc,tipodoc,tipocomprobante)
 select elem.nrosucursal,tipof, elem.nrofactura,ttfacturasgeneradas.mes,ttfacturasgeneradas.anio,ttfacturasgeneradas.nrodoc,ttfacturasgeneradas.tipodoc,tipoc FROM ttfacturasgeneradas;

close asientosjubpen;
--VALUES(1,elem.nrosucursal,elem.nrofactura,ttordenesgeneradas.nroorden,unaportejubpen.centro);
return true;
END;
$function$
