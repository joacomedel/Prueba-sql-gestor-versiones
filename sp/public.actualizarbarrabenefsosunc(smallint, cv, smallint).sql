CREATE OR REPLACE FUNCTION public.actualizarbarrabenefsosunc(smallint, character varying, smallint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	aux RECORD;
	titu RECORD;
	
	
BEGIN

if ($3 > 29)
	then
		UPDATE benefsosunc SET barratitu =$3 where nrodoctitu= $2 AND tipodoctitu = $1;		
	else
		SELECT INTO aux * FROM benefsosunc WHERE nrodoc = $2 AND tipodoc = $1;
		SELECT INTO titu * FROM persona WHERE nrodoc = aux.nrodoctitu AND tipodoc=aux.tipodoctitu;
		UPDATE benefsosunc SET barratitu = titu.barra WHERE nrodoctitu = aux.nrodoctitu AND tipodoctitu = aux.tipodoctitu;
		
end if;
RETURN 'true';
END;
$function$
