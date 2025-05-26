CREATE OR REPLACE FUNCTION public.bajartiposdoc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursoresta CURSOR FOR SELECT * FROM temptiposdoc;
	esta RECORD;
BEGIN
    OPEN cursoresta;
    FETCH cursoresta into esta;
    WHILE  found LOOP

        INSERT INTO tiposdoc VALUES(esta.tipodoc,esta.descrip);

    fetch cursoresta into esta;
    END LOOP;
    close cursoresta;
return 'true';
END;
$function$
