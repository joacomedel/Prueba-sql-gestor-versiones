CREATE OR REPLACE FUNCTION public.anularfacturaventainformeexpendioreintegro(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfoexpreintegro CURSOR FOR SELECT * FROM informefacturacionexpendioreintegro WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfoexpreintegro RECORD;
resp BOOLEAN;

BEGIN

open sitemsinfoexpreintegro;
fetch sitemsinfoexpreintegro into regsitemsinfoexpreintegro; 

  WHILE FOUND LOOP


INSERT INTO informefacturacionexpendioreintegro(nroinforme, idcentroinformefacturacion,  nroreintegro, anio, idcentroregional )
VALUES($3,$4,regsitemsinfoexpreintegro.nroreintegro,regsitemsinfoexpreintegro.anio,regsitemsinfoexpreintegro.idcentroregional);

 fetch sitemsinfoexpreintegro into regsitemsinfoexpreintegro; 
 END LOOP;
close sitemsinfoexpreintegro;


return resp;
END;
$function$
