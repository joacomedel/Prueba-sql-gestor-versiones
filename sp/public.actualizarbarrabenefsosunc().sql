CREATE OR REPLACE FUNCTION public.actualizarbarrabenefsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	cursortitu CURSOR FOR SELECT * FROM afilsosunc;
	titu RECORD;
	
BEGIN

	OPEN cursortitu;
	FETCH cursortitu into titu;
	WHILE found LOOP
		UPDATE benefsosunc SET barratitu = titu.barra WHERE nrodoctitu = titu.nrodoc AND tipodoctitu = titu.tipodoc;
	fetch cursortitu into titu;
	END LOOP;
close cursortitu;

return 'true';
END;
$function$
