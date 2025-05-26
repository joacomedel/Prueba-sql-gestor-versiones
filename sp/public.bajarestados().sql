CREATE OR REPLACE FUNCTION public.bajarestados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursoresta CURSOR FOR SELECT * FROM tempestados;
	esta RECORD;
BEGIN
    OPEN cursoresta;
    FETCH cursoresta into esta;
    WHILE  found LOOP

        INSERT INTO estados VALUES(esta.idestado,esta.descrip);

    fetch cursoresta into esta;
    END LOOP;
    close cursoresta;
return 'true';
END;
$function$
