CREATE OR REPLACE FUNCTION public.asentarfacturaaportesjubpenversion2(tipoc integer, tipof character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

elem RECORD;
aportesjubpen Cursor for select * from tempaportejubpenlic;
unaportejubpen record;
amuc double precision;
efectivo double precision;
ctacte double precision;
debito double precision;
credito  double precision;
centrov integer;
barra1 integer;
tdoc smallint;

BEGIN


efectivo = 0;
amuc = 0;
ctacte = 0;
debito = 0;
credito = 0;


open aportesjubpen;
fetch aportesjubpen into unaportejubpen;


SELECT into tdoc tipodoc FROM persona WHERE nrodoc = unaportejubpen.nrodoc;
 SELECT INTO barra1 barra FROM persona
      WHERE (nrodoc = unaportejubpen.nrodoc AND tipodoc = tdoc);

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
   tipofactura varchar(2),
   idaporte bigint
) WITHOUT OIDS;


SELECT  into centrov centro();

SELECT into elem nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(centrov,tipoc,tipof);


IF (unaportejubpen.idformapagotipos=1) THEN
   amuc = unaportejubpen.importetotal;
END IF;
IF (unaportejubpen.idformapagotipos=2) THEN
   efectivo = unaportejubpen.importetotal;
END IF;
IF (unaportejubpen.idformapagotipos=3) THEN
   ctacte = unaportejubpen.importetotal;
END IF;
IF (unaportejubpen.idformapagotipos=4) THEN
   debito = unaportejubpen.importetotal;
END IF;
IF (unaportejubpen.idformapagotipos=5) THEN
   credito = unaportejubpen.importetotal;
END IF;

INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,tipodoc,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura,barra)
VALUES(tipoc,elem.nrosucursal,elem.nrofactura,unaportejubpen.nrodoc,tdoc,1000,centrov,amuc,efectivo,debito,credito,ctacte,0,current_date,unaportejubpen.idformapagotipos,tipof,barra1);

INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
   VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,'50340',1,unaportejubpen.importe,concat('Aporte mes: ',unaportejubpen.mes,' Anio: ',unaportejubpen.anio),1);


  INSERT INTO ttfacturasgeneradas (nrosucursal,tipofactura,nrofactura,mes,anio,nrodoc,tipodoc,centro,tipocomprobante,idaporte)
         VALUES (elem.nrosucursal,tipof,elem.nrofactura,unaportejubpen.mes,unaportejubpen.anio,unaportejubpen.nrodoc,tdoc,centrov,tipoc,unaportejubpen.idaporte);

FETCH aportesjubpen INTO unaportejubpen;
      WHILE FOUND LOOP
         INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
         VALUES(tipoc,elem.nrosucursal,tipof,elem.nrofactura,'50340',1,unaportejubpen.importe,concat('Aporte mes: ',unaportejubpen.mes,' Anio: ',unaportejubpen.anio),1);

         INSERT INTO ttfacturasgeneradas (nrosucursal,tipofactura,nrofactura,mes,anio,nrodoc,tipodoc,centro,tipocomprobante,idaporte)
         VALUES (elem.nrosucursal,tipof,elem.nrofactura,unaportejubpen.mes,unaportejubpen.anio,unaportejubpen.nrodoc,tdoc,centrov,tipoc,unaportejubpen.idaporte);

         FETCH aportesjubpen INTO unaportejubpen;

      END LOOP;
      CLOSE aportesjubpen;

 --  inserta las facturas en ttfacturasgeneradas

 INSERT INTO facturaaporte(nrosucursal,tipofactura,nrofactura,mes,anio,nrodoc,tipodoc,tipocomprobante,idaporte)
 select elem.nrosucursal,tipof, elem.nrofactura,ttfacturasgeneradas.mes,ttfacturasgeneradas.anio,ttfacturasgeneradas.nrodoc,ttfacturasgeneradas.tipodoc,tipoc, ttfacturasgeneradas.idaporte FROM ttfacturasgeneradas;

--VALUES(1,elem.nrosucursal,elem.nrofactura,ttordenesgeneradas.nroorden,unaportejubpen.centro);
return true;
END;
$function$
