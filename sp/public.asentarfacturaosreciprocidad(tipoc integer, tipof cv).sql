CREATE OR REPLACE FUNCTION public.asentarfacturaosreciprocidad(tipoc integer, tipof character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
elem RECORD;
elemaux RECORD;
efectivo double precision = 0;
ctacte double precision = 0;
debito double precision = 0;
credito  double precision = 0;
descriposreci VARCHAR;
nrocuenta VARCHAR;

ordenesreciprocidad CURSOR FOR SELECT * FROM tempreciprocidad;
torden RECORD;

items CURSOR FOR SELECT * FROM tempitemsreci;
itemf RECORD;


BEGIN

CREATE TEMP TABLE ttfacturasgeneradas
(
   nrosucursal integer,
   nrofactura bigint,
   nroorden bigint,
   centro integer,
   tipocomprobante integer,
   tipofactura varchar(2),
   idaporte bigint
) WITHOUT OIDS;



open ordenesreciprocidad;
FETCH ordenesreciprocidad into torden;

if (torden.idformapagotipos = 2 or torden.idformapagotipos = 8) then
   efectivo = torden.importeTotal;
end if;
if (torden.idformapagotipos = 3) then
   ctacte = torden.importeTotal;
end if;
if (torden.idformapagotipos = 4) then
   debito = torden.importeTotal;
end if;
if (torden.idformapagotipos = 5) then
   credito = torden.importeTotal;
end if;

SELECT INTO elemaux nrosucursal, sgtenumero as nrofactura FROM devolvernrofactura(torden.centro,tipoc,tipof);

INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,nrodoc,barra,ctacontable,centro,importeamuc,importeefectivo,importedebito,importecredito,importectacte,importesosunc,fechaemision,formapago, tipofactura)
      VALUES(tipoc,elemaux.nrosucursal,elemaux.nrofactura,torden.nrocliente,torden.barra,10325,torden.centro,0,efectivo,debito,credito,ctacte,0,current_date,torden.idformapagotipos,tipof);


CLOSE ordenesreciprocidad;

open items;
FETCH items into itemf;
      WHILE FOUND LOOP
            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
            VALUES(tipoc,elemaux.nrosucursal,tipof,elemaux.nrofactura,itemf.idconcepto,itemf.cantidad,itemf.importe,itemf.descripcion,1);
        FETCH items into itemf;
        END LOOP;
close items;

open ordenesreciprocidad;
FETCH ordenesreciprocidad into torden;
 WHILE FOUND LOOP
   INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,nrofactura,nroorden,centro)
      VALUES(tipoc,elemaux.nrosucursal,tipof,elemaux.nrofactura,torden.nroorden,torden.centro);


   INSERT INTO ttfacturasgeneradas (nrosucursal,tipofactura,nrofactura,nroorden,centro,tipocomprobante)
      VALUES (elemaux.nrosucursal,tipof,elemaux.nrofactura,torden.nroorden,torden.centro,tipoc);

   FETCH ordenesreciprocidad into torden;
    END LOOP;
CLOSE ordenesreciprocidad;

return true;
END;
$function$
