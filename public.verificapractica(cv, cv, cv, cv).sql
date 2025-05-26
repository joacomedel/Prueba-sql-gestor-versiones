CREATE OR REPLACE FUNCTION public.verificapractica(character varying, character varying, character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	idpract		RECORD;
	subcapi		VARCHAR;
	resultado	BOOLEAN;

-- $1 = idsubespecialidad, $2=idcapitulo, $3=idsubcapitulo, $4=idpractica, $5 = Nombre de la tabla a actualizar
	
BEGIN
		


	SELECT INTO idpract *
	FROM	practica
	WHERE 	idnomenclador = $1 AND
		idcapitulo        = $2 AND
		idsubcapitulo     = $3 AND
		idpractica        = $4;
    
	if FOUND then
		resultado = true;
		else
		resultado = false;
		end if;

	return resultado;


END;
$function$
