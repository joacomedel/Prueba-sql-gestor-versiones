CREATE OR REPLACE FUNCTION public.actualizarbarrabenefreci()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursortitu CURSOR FOR SELECT * FROM afilreci;
	titu RECORD;
	
BEGIN

    OPEN cursortitu;
	FETCH cursortitu into titu;
	WHILE found LOOP
		UPDATE benefreci SET barratitu = titu.barra WHERE nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc;
	fetch cursortitu into titu;
	END LOOP;
	close cursortitu;

return 'true';
END;
$function$
