CREATE OR REPLACE FUNCTION public.bajardiscapacidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursordisc CURSOR FOR SELECT * FROM tempdiscapacidad;
	disc RECORD;
BEGIN

    OPEN cursordisc;
    FETCH cursordisc into disc;
    WHILE  found LOOP

        INSERT INTO discapacidad VALUES(disc.iddisc,disc.descrip,disc.porcentcober);

    fetch cursordisc into disc;
    END LOOP;
    close cursordisc;

return 'true';
END;
$function$
