CREATE OR REPLACE FUNCTION public.far_buscarhueconumeracion(bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
elnrofacturadesde bigint;
elmayor bigint;
cfactura refcursor;
unfac record;

BEGIN
     elnrofacturadesde = $1;
     OPEN cfactura FOR  SELECT *   FROM facturaventa
     WHERE nrosucursal = 4 and nrofactura >=elnrofacturadesde
     and tipocomprobante = 1 and tipofactura='FA' and fechaemision >='2014-05-01'
     order by nrofactura;
     FETCH cfactura into unfac;
     WHILE (FOUND and (elnrofacturadesde = unfac.nrofactura)) LOOP

                  elnrofacturadesde = elnrofacturadesde +1;
     FETCH cfactura into unfac;
     END LOOP;
     CLOSE cfactura;


return elnrofacturadesde;
END;
$function$
