CREATE OR REPLACE FUNCTION public.amnomencladorcinco()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	curtempnomencladorcinco CURSOR FOR SELECT * FROM tempnomencladorcinco;
	
		
	nomen		RECORD;
	practi		BOOLEAN;
	resultado	BOOLEAN;
	nomencla	BOOLEAN;
	capitulo	BOOLEAN;
	subcapitulo	BOOLEAN;
	
BEGIN
	resultado = false;
	OPEN curtempnomencladorcinco;	
	FETCH curtempnomencladorcinco INTO nomen;
	WHILE  found LOOP

	SELECT INTO nomencla * 
	FROM verificanomenclador(nomen.idnomenclador,'tempnomencladorcinco');
	
	if nomencla then
	
		SELECT INTO capitulo * 
		FROM verificacapitulo(nomen.idnomenclador,nomen.idcapitulo,'tempnomencladorcinco');
		
		if capitulo then
		 
			SELECT INTO subcapitulo * 
			FROM verificasubcapitulo(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,'tempnomencladorcinco');

			if subcapitulo then
	
				SELECT INTO practi * 
				FROM verificapractica(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,nomen.idpractica);

				if practi then
		
					UPDATE nomencladorcinco 
					SET    par     = nomen.par,
					       uno     = nomen.uno,
					       cantpar = nomen.cantpar,
					       cantuno = nomen.cantuno					
					
					WHERE 	idnomenclador	  = nomen.idnomenclador AND
						idcapitulo        = nomen.idcapitulo AND
						idsubcapitulo     = nomen.idsubcapitulo AND
						idpractica        = nomen.idpractica;
	
					else
		
					INSERT INTO practica 
					(idnomenclador, idcapitulo, idsubcapitulo, idpractica, pdescripcion)
					VALUES (nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,
						nomen.idpractica,nomen.descripcion);

					INSERT INTO nomencladorcinco
					(idnomenclador,idcapitulo,idsubcapitulo,idpractica,par,uno,
					cantpar,cantuno)
					VALUES (nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,
						nomen.idpractica,nomen.par,nomen.uno,
						nomen.cantpar,nomen.cantuno);

					
					end if; -- cierra el if de practica
				resultado = true;
					
				end if; -- cierra el if del subcapitulo
			end if;-- cierra el if del capitulo
		end if; -- cierra el if del nomenclador




	FETCH curtempnomencladorcinco INTO nomen;
	END LOOP;
	CLOSE curtempnomencladorcinco;
return resultado;
 
END;
$function$
