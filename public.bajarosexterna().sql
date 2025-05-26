CREATE OR REPLACE FUNCTION public.bajarosexterna()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursorosex CURSOR FOR SELECT * FROM temposexterna;
	osex RECORD;
BEGIN

    OPEN cursorosex;
    FETCH cursorosex into osex;
    WHILE  found LOOP

        INSERT INTO osexterna VALUES(osex.idosexterna,osex.descrip,osex.tel,osex.abreviatura);

    fetch cursorosex into osex;
    END LOOP;
    close cursorosex;

return 'true';
END;
$function$
