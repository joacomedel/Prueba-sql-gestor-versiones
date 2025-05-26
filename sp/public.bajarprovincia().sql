CREATE OR REPLACE FUNCTION public.bajarprovincia()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorprov CURSOR FOR SELECT * FROM tempprovincia;
	prov RECORD;
BEGIN

    OPEN cursorprov;
    FETCH cursorprov into prov;
    WHILE  found LOOP

        INSERT INTO provincia VALUES(prov.idprovincia,prov.descrip);

    fetch cursorprov into prov;
    END LOOP;
    close cursorprov;

return 'true';
END;
$function$
