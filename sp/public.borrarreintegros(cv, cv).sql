CREATE OR REPLACE FUNCTION public.borrarreintegros(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	reintegro RECORD;
	resultado boolean;

BEGIN
	SELECT INTO reintegro *
	FROM reintegros
	WHERE idafil = $1 and importe = $2;
	if FOUND then
			
		DELETE FROM reintegros WHERE idafil = $1 and importe = $2;
		INSERT INTO breintegros (idafil,importe)
			VALUES (reintegro.idafil, reintegro.importe);
		resultado = true;
		else

		resultado = false;
		end if;
	
    return resultado;


END;
$function$
