CREATE OR REPLACE FUNCTION public.bajarvinculos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursoresta CURSOR FOR SELECT * FROM tempvinculos;
	esta RECORD;
BEGIN
    OPEN cursoresta;
    FETCH cursoresta into esta;
    WHILE  found LOOP

        INSERT INTO vinculos VALUES(esta.idvin,esta.descrip);

    fetch cursoresta into esta;
    END LOOP;
    close cursoresta;
return 'true';
END;
$function$
