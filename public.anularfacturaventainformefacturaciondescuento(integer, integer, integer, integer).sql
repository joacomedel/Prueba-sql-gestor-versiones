CREATE OR REPLACE FUNCTION public.anularfacturaventainformefacturaciondescuento(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfodto CURSOR FOR SELECT * FROM informefacturaciondescuento WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfodto RECORD;


BEGIN

open sitemsinfodto;
fetch sitemsinfodto into regsitemsinfodto;

  WHILE FOUND LOOP
              INSERT INTO informefacturaciondescuento(idcentroinformefacturacion,nroinforme,mesingreso,anioingreso)
              VALUES($4,$3,regsitemsinfoapo.mesingreso,regsitemsinfoapo.anioingreso);
  
 fetch sitemsinfodto into regsitemsinfodto;
 END LOOP;
close sitemsinfodto;
return true;
END;
$function$
