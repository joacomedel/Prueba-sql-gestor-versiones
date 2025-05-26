CREATE OR REPLACE FUNCTION public.bajarcertpersonal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorcert CURSOR FOR SELECT * FROM tempcertpersonal;
	cert RECORD;
BEGIN

    OPEN cursorcert;
    FETCH cursorcert into cert;
    WHILE  found LOOP

        INSERT INTO certpersonal VALUES(cert.idcertpers,cert.cantaport,cert.idcateg);

    fetch cursorcert into cert;
    END LOOP;
    close cursorcert;

return 'true';
END;
$function$
