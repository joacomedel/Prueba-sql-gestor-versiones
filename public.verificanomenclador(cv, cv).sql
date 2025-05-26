CREATE OR REPLACE FUNCTION public.verificanomenclador(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	idnomen		VARCHAR;
	capi		VARCHAR;
	resultado 	BOOLEAN;
	tabla 		VARCHAR;

-- $1 = idnomenclador, $2 = Nombre de la tabla a actualizar
	
BEGIN
	tabla = $2;

	SELECT INTO idnomen idnomenclador
	FROM	nomenclador
	WHERE 	idnomenclador = $1;
    
	if FOUND then
		resultado = true;
		else
		resultado = false;

		if tabla = 'tempnomencladoruno' then
			UPDATE tempnomencladoruno SET error = 'nomenclador'
			WHERE 	idnomenclador = $1;
			end if;
		if tabla = 'tempnomencladordos' then
			UPDATE tempnomencladordos SET error = 'nomenclador'
			WHERE 	idnomenclador = $1;
			end if;
		if tabla = 'tempnomencladorcinco' then
			UPDATE tempnomencladorcinco SET error = 'nomenclador'
			WHERE 	idnomenclador = $1;
			end if;
		end if;

	return resultado;
END;
$function$
