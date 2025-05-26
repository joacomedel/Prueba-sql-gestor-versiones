CREATE OR REPLACE FUNCTION public.bajartestadocivil()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursoresta CURSOR FOR SELECT * FROM temptestadocivil;
	esta RECORD;
BEGIN
    OPEN cursoresta;
    FETCH cursoresta into esta;
    WHILE  found LOOP

        INSERT INTO testadocivil VALUES(esta.idestcivil,esta.descrip);

    fetch cursoresta into esta;
    END LOOP;
    close cursoresta;
return 'true';
END;
$function$
