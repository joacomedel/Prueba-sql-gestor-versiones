CREATE OR REPLACE FUNCTION public.determinarregularidad(integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
   afiliado RECORD;
   resultado boolean;
   verif RECORD;
	
BEGIN
resultado = 'true';
SELECT INTO afiliado * FROM persona WHERE tipodoc = $2 AND nrodoc = $3;
if NOT FOUND
	then
		RAISE EXCEPTION 'NO EXISTE LA PERSONA EN LA BASE DE DATOS'; 
	else
		SELECT INTO verif * FROM verificacion WHERE codigo = '0105' AND nrodoc = $3;
		if FOUND
			then
				resultado = 'false';
		end if;
end if;


if NOT resultado 
	then
		if($1 = 1)
			then 
				UPDATE afilsosunc SET idestado = 8 WHERE tipodoc = $2 AND nrodoc = $3;
		end if;
		if($1 = 2)
			then 
				UPDATE afilsosunc SET idestado = 5 WHERE tipodoc = $2 AND nrodoc = $3;
				
		end if;
		if($1 = 3)
			then 
				UPDATE afilsosunc SET idestado = 7 WHERE tipodoc = $2 AND nrodoc = $3;
				
		end if;
end if;
return 'true';
END;
$function$
