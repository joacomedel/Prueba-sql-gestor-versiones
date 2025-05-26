CREATE OR REPLACE FUNCTION public.anularfacturaventainformeaporte(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfoaporte CURSOR FOR SELECT * FROM informefacturacionaporte WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfoaporte RECORD;


BEGIN

open sitemsinfoaporte;
fetch sitemsinfoaporte into regsitemsinfoaporte; 

  WHILE FOUND LOOP


INSERT INTO informefacturacionaporte(idcentroinformefacturacion,nroinforme,idcentroregionaluso,idaporte)
VALUES($4,$3,regsitemsinfoaporte.idcentroregionaluso,regsitemsinfoaporte.idaporte);

 fetch sitemsinfoaporte into regsitemsinfoaporte; 
 END LOOP;
close sitemsinfoaporte;

--KR 2021-07-05 no estaba esto, se ve esta fue la primera vez que se anulo un comprobante de este tipo y por eso se dieron cuenta que no elimina de la ctacte
 PERFORM anulardeudainfoygenerarnuevadeuda($1,$2,$3,$4);
return true;
END;
$function$
