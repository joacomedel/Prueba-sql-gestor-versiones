CREATE OR REPLACE FUNCTION public.vincularordenconfactura(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


ordenfac CURSOR FOR SELECT * FROM informefacturacionreciprocidad WHERE nroinforme= $1 AND idcentroinformefacturacion=$2;
tordenfac RECORD;
elem RECORD;


BEGIN

SELECT INTO elem tipocomprobante, nrosucursal, nrofactura, tipofactura
FROM informefacturacion
WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
open ordenfac;
FETCH ordenfac into tordenfac;
 
     WHILE FOUND LOOP
         --vinculo cada orden con su correspondiente factura
        INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,nrofactura,nroorden,centro,idcomprobantetipos)
            VALUES(elem.tipocomprobante,elem.nrosucursal,elem.tipofactura,elem.nrofactura,tordenfac.nroorden,tordenfac.centro,tordenfac.idcomprobantetipos);
       FETCH ordenfac into tordenfac;
     END LOOP;

CLOSE ordenfac;

return true;
END;
$function$
