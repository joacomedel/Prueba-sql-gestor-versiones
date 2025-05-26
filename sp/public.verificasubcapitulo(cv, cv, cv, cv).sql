CREATE OR REPLACE FUNCTION public.verificasubcapitulo(character varying, character varying, character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	idsubcapi	VARCHAR;
	capitulo	VARCHAR;
	resultado	BOOLEAN;
	tabla		VARCHAR;


-- $1 = idnomenclador, $2=idcapitulo, $3=idsubcapitulo, $4 = Nombre de la tabla a actualizar	
BEGIN

	tabla = $4;


	SELECT INTO idsubcapi idsubcapitulo
	FROM	subcapitulo
	WHERE 	idnomenclador     = $1 AND
		idcapitulo        = $2 AND
		idsubcapitulo     = $3;
    
	if FOUND then
		resultado = true;
		else
		resultado = false;
		if tabla = 'tempnomencladoruno' then
			UPDATE tempnomencladoruno SET error = 'subcapitulo'
			WHERE 	idnomenclador     = $1 AND
				idcapitulo        = $2 AND
				idsubcapitulo     = $3;
			end if;
		if tabla = 'tempnomencladordos' then
			UPDATE tempnomencladordos SET error = 'subcapitulo'
			WHERE 	idnomenclador     = $1 AND
				idcapitulo        = $2 AND
				idsubcapitulo     = $3;
			end if;
		if tabla = 'tempnomencladorcinco' then
			UPDATE tempnomencladorcinco SET error = 'subcapitulo'
			WHERE 	idnomenclador     = $1 AND
				idcapitulo        = $2 AND
				idsubcapitulo     = $3;
			end if;
		end if;
	
	return resultado;


END;
$function$
