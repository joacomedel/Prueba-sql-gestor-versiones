CREATE OR REPLACE FUNCTION public.anularfacturaventainformeamuc(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfoamuc CURSOR FOR SELECT * FROM informefacturacionamuc WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfoamuc RECORD;


BEGIN

open sitemsinfoamuc;
fetch sitemsinfoamuc into regsitemsinfoamuc; 

  WHILE FOUND LOOP


INSERT INTO informefacturacionamuc(idcentroinformefacturacion,nroinforme,centro,nroorden)
VALUES($4,$3,regsitemsinfoamuc.centro,regsitemsinfoamuc.nroorden);

 fetch sitemsinfoamuc into regsitemsinfoamuc; 
 END LOOP;
close sitemsinfoamuc;

 PERFORM anulardeudainfoygenerarnuevadeuda($1,$2,$3,$4);

return true;
END;
$function$
