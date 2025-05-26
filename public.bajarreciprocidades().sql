CREATE OR REPLACE FUNCTION public.bajarreciprocidades()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursoresta CURSOR FOR SELECT * FROM tempreciprocidades;
	esta RECORD;
BEGIN
    OPEN cursoresta;
    FETCH cursoresta into esta;
    WHILE  found LOOP

        INSERT INTO reciprocidades VALUES(esta.idreci,esta.descrip);

    fetch cursoresta into esta;
    END LOOP;
    close cursoresta;
return 'true';
END;
$function$
