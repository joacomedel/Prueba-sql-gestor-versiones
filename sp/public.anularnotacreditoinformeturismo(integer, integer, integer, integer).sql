CREATE OR REPLACE FUNCTION public.anularnotacreditoinformeturismo(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfoturismo CURSOR FOR SELECT * FROM informefacturacionturismo WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfoturismo RECORD;

resp BOOLEAN;

BEGIN

open sitemsinfoturismo;
fetch sitemsinfoturismo into regsitemsinfoturismo;

  WHILE FOUND LOOP


INSERT INTO informefacturacionturismo(idcentroinformefacturacion,nroinforme,idconsumoturismo,idcentroconsumoturismo)
VALUES($4,$3,regsitemsinfoturismo.idconsumoturismo,regsitemsinfoturismo.idcentroconsumoturismo);

 fetch sitemsinfoturismo into regsitemsinfoturismo;
 END LOOP;
close sitemsinfoturismo;


return resp;
END;
$function$
