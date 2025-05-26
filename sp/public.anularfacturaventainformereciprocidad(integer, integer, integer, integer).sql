CREATE OR REPLACE FUNCTION public.anularfacturaventainformereciprocidad(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
-- $1: nroinforme anulado
-- $2: idcentroinformefacturacion anulado
-- $3: nroinforme creado en pendiente de facturacion
-- $4: idcentroinformefacturacion creado en pendiente de facturacion

--cursor con los datos que se deben cargar en la tabla del nuevo informe
sitemsinforeciprocidad CURSOR FOR SELECT * FROM informefacturacionreciprocidad WHERE nroinforme= $1 and idcentroinformefacturacion=$2;
regsitemsinforeciprocidad RECORD;

resp BOOLEAN;

BEGIN

open sitemsinforeciprocidad;
fetch sitemsinforeciprocidad into regsitemsinforeciprocidad; 

  WHILE FOUND LOOP


        INSERT INTO informefacturacionreciprocidad(idcentroinformefacturacion,nroinforme,centro,nroorden,idosreci,idprestador,fechauso,importe,idcomprobantetipos,nrodoc,tipodoc,barra)
        VALUES($4,$3,regsitemsinforeciprocidad.centro,regsitemsinforeciprocidad.nroorden,regsitemsinforeciprocidad.idosreci,regsitemsinforeciprocidad.idprestador,regsitemsinforeciprocidad.fechauso
        ,regsitemsinforeciprocidad.importe,regsitemsinforeciprocidad.idcomprobantetipos,regsitemsinforeciprocidad.nrodoc
        ,regsitemsinforeciprocidad.tipodoc,regsitemsinforeciprocidad.barra);

        fetch sitemsinforeciprocidad into regsitemsinforeciprocidad;
 END LOOP;
 close sitemsinforeciprocidad;

 PERFORM anulardeudainfoygenerarnuevadeuda($1,$2,$3,$4);


return resp;
END;
$function$
