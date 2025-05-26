CREATE OR REPLACE FUNCTION public.anularfacturaventainformesolicitudfinanciacion(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinfosolicitudfinanciacion CURSOR FOR SELECT * FROM informefacturacionsolicitudfinanciacion WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinfosolicitudfinanciacion RECORD;

resp BOOLEAN;

BEGIN

open sitemsinfosolicitudfinanciacion;
fetch sitemsinfosolicitudfinanciacion into regsitemsinfosolicitudfinanciacion; 

  WHILE FOUND LOOP


INSERT INTO informefacturacionsolicitudfinanciacion(idcentroinformefacturacion,nroinforme,idsolicitudfinanciacion,idcentrosolicitudfinanciacion)
VALUES($4,$3,regsitemsinfosolicitudfinanciacion.idsolicitudfinanciacion,regsitemsinfosolicitudfinanciacion.idcentrosolicitudfinanciacion);

 fetch sitemsinfosolicitudfinanciacion into regsitemsinfosolicitudfinanciacion; 
 END LOOP;
close sitemsinfosolicitudfinanciacion;


return resp;
END;
$function$
