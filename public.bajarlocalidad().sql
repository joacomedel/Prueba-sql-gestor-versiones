CREATE OR REPLACE FUNCTION public.bajarlocalidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorloca CURSOR FOR SELECT * FROM templocalidad;
	loca RECORD;
BEGIN

    OPEN cursorloca;
    FETCH cursorloca into loca;
    WHILE  found LOOP

        INSERT INTO localidad VALUES(loca.idlocalidad,loca.descrip,loca.codpostal,loca.caracttel);

    fetch cursorloca into loca;
    END LOOP;
    close cursorloca;

return 'true';
END;
$function$
