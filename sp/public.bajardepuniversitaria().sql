CREATE OR REPLACE FUNCTION public.bajardepuniversitaria()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursordepe CURSOR FOR SELECT * FROM tempdepuniversitaria;
	depe RECORD;
BEGIN

    OPEN cursordepe;
    FETCH cursordepe into depe;
    WHILE  found LOOP

        INSERT INTO depuniversitaria VALUES(depe.iddepen,depe.descrip,depe.iddireccion);

    fetch cursordepe into depe;
    END LOOP;
    close cursordepe;

return 'true';
END;
$function$
