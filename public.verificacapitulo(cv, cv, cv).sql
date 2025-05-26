CREATE OR REPLACE FUNCTION public.verificacapitulo(character varying, character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	idcapi		VARCHAR;
	resultado	BOOLEAN;
	tabla		VARCHAR;

-- $1 = idnomenclador, $2=idcapitulo, $3 = Nombre de la tabla a actualizar
BEGIN
	tabla = $3;
	
	SELECT INTO idcapi idcapitulo
	FROM	capitulo
	WHERE 	idnomenclador     = $1 AND
		idcapitulo        = $2;
    
	if FOUND then
		resultado = true;
		else
		resultado = false;
		if tabla = 'tempnomencladoruno' then
			UPDATE tempnomencladoruno SET error = 'capitulo'
			WHERE 	idnomenclador     = $1 AND
				idcapitulo        = $2;
			end if;
		if tabla = 'tempnomencladordos' then
			UPDATE tempnomencladordos SET error = 'capitulo'
			WHERE 	idnomenclador     = $1 AND
				idcapitulo        = $2;
			end if;
		if tabla = 'tempnomencladorcinco' then
			UPDATE tempnomencladorcinco SET error = 'capitulo'
			WHERE 	idnomenclador     = $1 AND
				idcapitulo        = $2;
			end if;
		end if;
		
		
	return resultado;

END;
$function$
