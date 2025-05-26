CREATE OR REPLACE FUNCTION public.anularfacturaventainformefacturacionaportescontribuciones(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfoapo CURSOR FOR SELECT * FROM informefacturacionaportescontribuciones WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfoapo RECORD;


BEGIN

open sitemsinfoapo;
fetch sitemsinfoapo into regsitemsinfoapo;

  WHILE FOUND LOOP
              INSERT INTO informefacturacionaportescontribuciones(idcentroinformefacturacion,nroinforme,mesingreso,anioingreso)
              VALUES($4,$3,regsitemsinfoapo.mesingreso,regsitemsinfoapo.anioingreso);

 fetch sitemsinfoapo into regsitemsinfoapo;
 END LOOP;
close sitemsinfoapo;
return true;
END;
$function$
