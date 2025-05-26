CREATE OR REPLACE FUNCTION public.amnomencladordos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	curtempnomencladordos CURSOR FOR SELECT * FROM tempnomencladordos;
	
		
	nomen		RECORD;
	practi		BOOLEAN;
	resultado	BOOLEAN;
	nomencla	BOOLEAN;
	capitulo	BOOLEAN;
	subcapitulo	BOOLEAN;
	
BEGIN
	resultado = false;
	OPEN curtempnomencladordos;	
	FETCH curtempnomencladordos INTO nomen;
	WHILE  found LOOP

	SELECT INTO nomencla * 
	FROM verificanomenclador(nomen.idnomenclador,'tempnomencladordos');
	
	if nomencla then
	
		SELECT INTO capitulo * 
		FROM verificacapitulo(nomen.idnomenclador,nomen.idcapitulo,'tempnomencladordos');
		
		if capitulo then
	
			SELECT INTO subcapitulo * 
			FROM verificasubcapitulo(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,'tempnomencladordos');

			if subcapitulo then
	
				SELECT INTO practi * 
				FROM verificapractica(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,nomen.idpractica);

				if practi then
		
					UPDATE nomencladordos 
					SET    pmhonorario1 = nomen.pmhonorario1,
					       pmcantidad1  = nomen.pmcantidad1,
					       pmgastos     = nomen.pmgastos,
					       pmcantgastos = nomen.pmcantgastos					
					
					WHERE 	idnomenclador	  = nomen.idnomenclador AND
						idcapitulo        = nomen.idcapitulo AND
						idsubcapitulo     = nomen.idsubcapitulo AND
						idpractica        = nomen.idpractica;

					
					else
		
					INSERT INTO practica 
					(idnomenclador, idcapitulo, idsubcapitulo, idpractica, pdescripcion)
					VALUES (nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,
						nomen.idpractica,nomen.descripcion);

					INSERT INTO nomencladordos
					(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,
					pmgastos,pmcantgastos)
					VALUES (nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,
						nomen.idpractica,nomen.pmhonorario1,nomen.pmcantidad1,
						nomen.pmgastos,nomen.pmcantgastos);

					
					end if; -- cierra el if de practica
                Delete From tempnomencladordos where idnomenclador	  = nomen.idnomenclador AND
					                           	idcapitulo        = nomen.idcapitulo AND
					                            idsubcapitulo     = nomen.idsubcapitulo AND
                                 				idpractica        = nomen.idpractica;
				resultado = true; 					
					
				end if; -- cierra el if del subcapitulo
			end if;-- cierra el if del capitulo
		end if; -- cierra el if del nomenclador




	FETCH curtempnomencladordos INTO nomen;
	END LOOP;
	CLOSE curtempnomencladordos;
return resultado;
 
END;
$function$
