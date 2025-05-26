CREATE OR REPLACE FUNCTION public.borrarusuarios(character varying, character varying, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	reintegro RECORD;
	resultado boolean;

BEGIN
	INSERT INTO usuarioborrados (dni,nombre,apellido,tipodoc,fecha) 
	VALUES ($3,$1,$2,$4,current_date);
	DELETE FROM usuariomodulo WHERE  dni = $3 and tipodoc = $4 ;
	DELETE FROM usuario WHERE  dni = $3 and tipodoc = $4 ;
	resultado = false;
	return resultado;
END;
$function$
