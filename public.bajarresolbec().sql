CREATE OR REPLACE FUNCTION public.bajarresolbec()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorreso CURSOR FOR SELECT * FROM tempresolbec;
	reso RECORD;
BEGIN

    OPEN cursorreso;
    FETCH cursorreso into reso;
    WHILE  found LOOP

        INSERT INTO resolbec VALUES(reso.idresolbe,reso.fechainilab,reso.fechafinlab,reso.idcateg,reso.nroresol,reso.iddepen);

    fetch cursorreso into reso;
    END LOOP;
    close cursorreso;

return 'true';
END;
$function$
