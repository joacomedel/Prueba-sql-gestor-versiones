CREATE OR REPLACE FUNCTION public.amnomenclador()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	curtempnomenclador CURSOR FOR SELECT * FROM tempnomenclador;
	
		
	nomen RECORD;
	idnomencla   VARCHAR;
	resultado boolean;

BEGIN
	OPEN curtempnomenclador;	
	FETCH curtempnomenclador INTO nomen;
	WHILE  found LOOP
		SELECT INTO idnomencla idnomenclador FROM nomenclador WHERE idnomenclador = nomen.idnomenclador ;
		if FOUND then

		UPDATE nomenclador 
		SET 	ndescripcion= nomen.ndescripcion,
			nlibro	    = nomen.nlibro,
			nespecialidad = nomen.nespecialidad
		WHERE idnomenclador = nomen.idnomenclador ;
		
		else

		INSERT INTO nomenclador (idnomenclador, ndescripcion, nlibro, nespecialidad )
		VALUES (nomen.idnomenclador, nomen.ndescripcion, nomen.nlibro, nomen.nespecialidad );
		
		
		end if;
		
	DELETE FROM tempnomenclador WHERE idnomenclador = nomen.idnomenclador ;

	FETCH curtempnomenclador INTO nomen;
	END LOOP;
	CLOSE curtempnomenclador;

    return true;


END;
$function$
