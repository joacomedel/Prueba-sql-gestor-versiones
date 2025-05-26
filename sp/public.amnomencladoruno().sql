CREATE OR REPLACE FUNCTION public.amnomencladoruno()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	curtempnomencladoruno CURSOR FOR SELECT * FROM tempnomencladoruno ;
        --where nullvalue(error);
	
		
	nomen		RECORD;
	practi		BOOLEAN;
	resultado	BOOLEAN;
	nomencla	BOOLEAN;
	capitulo	BOOLEAN;
	subcapitulo	BOOLEAN;
	rusuario RECORD;
	
BEGIN

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;

	resultado = false;
	OPEN curtempnomencladoruno;	
	FETCH curtempnomencladoruno INTO nomen;
	WHILE  found LOOP

	SELECT INTO nomencla * FROM verificanomenclador(nomen.idnomenclador,'tempnomencladoruno');
	if NOT nomencla then
	    --UPDATE asistencial_nomenclador SET anerror = 'No existe el nomenclador' WHERE idnomenclador = nomen.idnomenclador;
              INSERT INTO nomenclador(idnomenclador, ndescripcion, nlibro, nespecialidad) VALUES(nomen.idnomenclador,concat(nomen.idnomenclador,' Cargado Automaticamente con Archivo'),'','');
                
        END IF;      
	SELECT INTO capitulo * FROM verificacapitulo(nomen.idnomenclador,nomen.idcapitulo,'tempnomencladoruno');
	if NOT capitulo then
	    --UPDATE asistencial_nomenclador SET anerror = 'No existe el capitulo' WHERE idnomenclador = nomen.idnomenclador AND idcapitulo=nomen.idcapitulo;
            insert into capitulo (idnomenclador,idcapitulo,cdescripcion,cactivo) values(nomen.idnomenclador,nomen.idcapitulo,concat(nomen.idnomenclador,'_',nomen.idcapitulo,' Cargado Automaticamente con Archivo'),true);
	END IF;
	SELECT INTO subcapitulo * FROM verificasubcapitulo(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,'tempnomencladoruno');
	IF NOT subcapitulo then 
	--UPDATE asistencial_nomenclador SET anerror = 'No existe el subcapitulo' WHERE idnomenclador = nomen.idnomenclador AND idcapitulo=nomen.idcapitulo AND idsubcapitulo=nomen.idsubcapitulo;
          insert into subcapitulo(idnomenclador,idcapitulo,idsubcapitulo,scdescripcion,scactivo) values(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,concat(nomen.idnomenclador,'_',nomen.idcapitulo,'_',nomen.idsubcapitulo,' Cargado Automaticamente con Archivo'),true);
        END IF;
				SELECT INTO practi * FROM verificapractica(nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,nomen.idpractica);
				if practi then 
					--Guardo el Historico
					INSERT INTO nomencladorunohistorico(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,pmactivo,pmidusuario,nuhobservacion) 
					(SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,pmactivo,rusuario.idusuario as pmidusuario,nomen.error  
						FROM nomencladoruno WHERE idnomenclador	  = nomen.idnomenclador AND
									 idcapitulo        = nomen.idcapitulo AND
									idsubcapitulo     = nomen.idsubcapitulo AND
									idpractica        = nomen.idpractica);
                                         --MaLaPi 27-09-2022 Limpio el error de la temporal que se usa para poner una observacion en el historico
                                          UPDATE tempnomencladoruno  SET error = null  WHERE idnomenclador = nomen.idnomenclador AND idcapitulo= nomen.idcapitulo AND idsubcapitulo = nomen.idsubcapitulo AND idpractica =nomen.idpractica;

 
 					UPDATE nomencladoruno 
					SET    pmhonorario1 = nomen.pmhonorario1,
					       pmcantidad1  = nomen.pmcantidad1,
					       pmhonorario2 = nomen.pmhonorario2, 
					       pmcantidad2  = nomen.pmcantidad2,
					       pmhonorario3 = nomen.pmhonorario3,
					       pmcantidad3  = nomen.pmcantidad3,
					       pmgastos     = nomen.pmgastos,
					       pmcantgastos = nomen.pmcantgastos					
					
					WHERE 	idnomenclador	  = nomen.idnomenclador AND
						idcapitulo        = nomen.idcapitulo AND
						idsubcapitulo     = nomen.idsubcapitulo AND
						idpractica        = nomen.idpractica;

                                         UPDATE practica 
					SET    pdescripcion = nomen.descripcion
                                               ,nrocuentac = nomen.nrocuentac
                                               ,activo = true
      				
					
					WHERE 	idnomenclador	  = nomen.idnomenclador AND
						idcapitulo        = nomen.idcapitulo AND
						idsubcapitulo     = nomen.idsubcapitulo AND
						idpractica        = nomen.idpractica;


					resultado = true; 
					
					else
		
					INSERT INTO practica 
					(idnomenclador, idcapitulo, idsubcapitulo, idpractica, pdescripcion,nrocuentac)
					VALUES (nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,
						nomen.idpractica,nomen.descripcion,nomen.nrocuentac);

					INSERT INTO nomencladoruno
					(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,
					pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos)
					VALUES (nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,
						nomen.idpractica,nomen.pmhonorario1,nomen.pmcantidad1,
						nomen.pmhonorario2,nomen.pmcantidad2,nomen.pmhonorario3,
						nomen.pmcantidad3,nomen.pmgastos,nomen.pmcantgastos);
                                         --Tambien guardo en el Historico cuando la doy de alta
                                        INSERT INTO nomencladorunohistorico(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,pmactivo,pmidusuario,nuhobservacion) 
					(SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,pmactivo,rusuario.idusuario as pmidusuario,nomen.error  
						FROM nomencladoruno WHERE idnomenclador	  = nomen.idnomenclador AND
									 idcapitulo        = nomen.idcapitulo AND
									idsubcapitulo     = nomen.idsubcapitulo AND
									idpractica        = nomen.idpractica);
                                         --MaLaPi 27-09-2022 Limpio el error de la temporal que se usa para poner una observacion en el historico
                                          UPDATE tempnomencladoruno  SET error = null  WHERE idnomenclador = nomen.idnomenclador AND idcapitulo= nomen.idcapitulo AND idsubcapitulo = nomen.idsubcapitulo AND idpractica =nomen.idpractica;

					resultado = true; 
					end if; -- cierra el if de practica
					
				
			
		

	FETCH curtempnomencladoruno INTO nomen;
	END LOOP;
	CLOSE curtempnomencladoruno;
return resultado;
 
END;
$function$
