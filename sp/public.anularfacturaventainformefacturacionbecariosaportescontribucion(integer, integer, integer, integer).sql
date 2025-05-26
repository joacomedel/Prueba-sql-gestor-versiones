CREATE OR REPLACE FUNCTION public.anularfacturaventainformefacturacionbecariosaportescontribucion(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfobec CURSOR FOR SELECT * FROM informefacturacionbecariosaportescontribuciones WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfobec RECORD;


BEGIN

open sitemsinfobec;
fetch sitemsinfobec into regsitemsinfobec;

  WHILE FOUND LOOP
              INSERT INTO informefacturacionbecariosaportescontribuciones(idcentroinformefacturacion,nroinforme,idcentroregionaluso,idaporte)
              VALUES($4,$3,regsitemsinfobec.idcentroregionaluso,regsitemsinfobec.idaporte);

 fetch sitemsinfobec into regsitemsinfobec;
 END LOOP;
close sitemsinfobec;
return true;
END;
$function$
