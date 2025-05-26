CREATE OR REPLACE FUNCTION public.asentarfacturainformefacturacionreciprocidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

resp BOOLEAN;
rpta BOOLEAN;

informefac CURSOR FOR SELECT * FROM tempfacturainforme;
tinformefac RECORD;



BEGIN

   SELECT INTO rpta * FROM asentarfacturainformefacturacion();

--vinculo cada orden con su correspondiente factura
open informefac;
FETCH informefac into tinformefac;
 
     WHILE FOUND LOOP
              SELECT INTO resp * FROM vincularordenconfactura(tinformefac.nroinforme,tinformefac.idcentroinformefacturacion);
      FETCH informefac into tinformefac;
      END LOOP;

CLOSE informefac;

return rpta;
END;
$function$
