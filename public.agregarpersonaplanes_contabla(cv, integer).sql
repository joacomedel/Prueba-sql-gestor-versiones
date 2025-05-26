CREATE OR REPLACE FUNCTION public.agregarpersonaplanes_contabla(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    	rplanes refcursor;
    	person RECORD;
	plancobpers RECORD;
	vplananterior integer;
	resultado boolean;
	vrequiereytiene boolean;
	vrequiereytieneacumulado boolean; --Para los casos donde los planes de cobertura tienen mas de una configuracion para el mismo plan
	nrodocu alias for $1;
	tipodocu alias for $2;

BEGIN
	resultado = true;
	vrequiereytieneacumulado = false;
	vplananterior = 0;
	OPEN rplanes FOR SELECT CASE WHEN not nullvalue(br.barratitu) THEN br.barratitu WHEN not nullvalue(bs.barratitu) THEN bs.barratitu ELSE 0 END as barratitu
 	                ,p.fechanac,p.nrodoc,p.tipodoc,p.barra,p.sexo,extract(year FROM age(CURRENT_DATE,p.fechanac)) as edad
 	                ,pca.*
			FROM plancobertura 
			NATURAL JOIN plancobertura_automaticos as pca 
			JOIN persona p ON (nrodoc =nrodocu /* '20096255'*/ /*54851772*/ AND tipodoc = tipodocu)
			LEFT JOIN benefreci br ON (p.nrodoc = br.nrodoc AND p.tipodoc = br.tipodoc AND p.barra > 100)
			LEFT JOIN benefsosunc bs ON (p.nrodoc = bs.nrodoc AND p.tipodoc = bs.tipodoc AND p.barra < 100)
			WHERE nullvalue(pcafechahasta) 
			ORDER BY idplancoberturas;
	FETCH rplanes into person;
	WHILE  found LOOP
	vrequiereytiene = true;
	RAISE NOTICE 'Plan de Cobertura (%)', person.idplancoberturas;
	IF (not nullvalue(person.pcasexo) )THEN 
		--vrequiere = vrequiere AND true;
		IF (person.sexo = person.pcasexo) THEN
			vrequiereytiene = vrequiereytiene AND true;
		ELSE 
			RAISE NOTICE 'No cumple Sexo';
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
	END IF;
----pcaedaddesde	pcaedadhasta
	IF (not nullvalue(person.pcaedaddesde))THEN 
		IF (person.pcaedaddesde <= person.edad ) THEN
			vrequiereytiene = vrequiereytiene AND true;
		ELSE 
			RAISE NOTICE 'No cumple edad desde';
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
	END IF;
	IF (not nullvalue(person.pcaedadhasta))THEN 
		IF (person.pcaedadhasta >= person.edad) THEN
			vrequiereytiene = vrequiereytiene AND true;
		ELSE 
			RAISE NOTICE 'No cumple edad hasta';
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
	END IF;
-----pcabarradesde	pcabarrahasta		
	IF (not nullvalue(person.pcabarradesde))THEN 
		IF (person.pcabarradesde <= person.barra ) THEN
			vrequiereytiene = vrequiereytiene AND true;
		ELSE 
			RAISE NOTICE 'No cumple barra desde (%) (%)', person.barra,person.pcabarradesde;
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
	END IF;
	IF (not nullvalue(person.pcabarrahasta))THEN 
		IF (person.pcabarrahasta >= person.barra) THEN
			vrequiereytiene = vrequiereytiene AND true;
		ELSE 
			RAISE NOTICE 'No cumple barra hasta (%)', person.barra;
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
	END IF;
----pcabarratitudesde	pcabarratituhasta
	IF (not nullvalue(person.pcabarratitudesde))THEN 
		IF (person.barratitu <> 0 ) THEN 
			IF (person.pcabarratitudesde >= person.barratitu ) THEN
				vrequiereytiene = vrequiereytiene AND true;
			ELSE 
				RAISE NOTICE 'No cumple barra titu desde';
				vrequiereytiene = vrequiereytiene AND false;
			END IF;
		ELSE -- Se trata de un titular
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
		
	END IF;
	IF (not nullvalue(person.pcabarratituhasta))THEN 
		IF (person.barratitu <> 0 ) THEN 
			IF (person.pcabarratitudesde <= person.barratitu ) THEN
				vrequiereytiene = vrequiereytiene AND true;
			ELSE 
				RAISE NOTICE 'No cumple barra titu hasta';
				vrequiereytiene = vrequiereytiene AND false;
			END IF;
		ELSE -- Se trata de un titular
			vrequiereytiene = vrequiereytiene AND false;
		END IF;
	END IF;
	IF vplananterior = 0 OR vplananterior <> person.idplancoberturas THEN
		vplananterior = person.idplancoberturas;
		vrequiereytieneacumulado = vrequiereytiene;
	ELSE 
		vrequiereytieneacumulado = vrequiereytieneacumulado OR vrequiereytiene;
	END IF;
---- Verifico a ver si la persona tiene el plan cargado
	SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = person.idplancoberturas;
	IF FOUND THEN 
------pcadiaspermanencia
		IF (not nullvalue(person.pcadiaspermanencia))THEN  
			--- MaLaPi Tener en cuenta que la permanencia se verifica con la fecha de alta, no con la fecha de ingreso
			IF (nullvalue(plancobpers.pcpfechaalta) OR (CURRENT_DATE > plancobpers.pcpfechaalta + person.pcadiaspermanencia)) THEN
				vrequiereytieneacumulado = false;
				RAISE NOTICE 'No cumple permanencia (%)',vrequiereytieneacumulado;
				
			END IF;
		END IF;
		IF not vrequiereytieneacumulado THEN -- Tiene el plan, pero no verifica alguna de sus condiciones.
                        RAISE NOTICE 'Tenia el Plan y no Corresponde, lo doy de baja (%) ', person.idplancoberturas; 
			UPDATE plancobpersona SET pcpfechafin = CURRENT_DATE WHERE nrodoc = person.nrodoc 
				AND tipodoc = person.tipodoc AND idplancoberturas = person.idplancoberturas; 
		ELSE 
                        RAISE NOTICE 'No lo tiene y Corresponde, lo doy de alta (%) ', person.idplancoberturas; 
			UPDATE plancobpersona SET pcpfechafin = null WHERE nrodoc = person.nrodoc 
				AND tipodoc = person.tipodoc AND idplancoberturas = person.idplancoberturas; 

		END IF;
		
	ELSE -- No tiene el plan cargado
		IF vrequiereytieneacumulado AND  person.pcaaltaautomatica THEN -- Tiene el plan, pero no verifica alguna de sus condiciones. 
			INSERT INTO plancobpersona(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES (person.idplancoberturas::varchar,person.nrodoc,person.tipodoc,person.idplancoberturas,CURRENT_DATE);
                        RAISE NOTICE 'No lo tiene y Corresponde, lo doy de alta (%) ', person.idplancoberturas; 

		END IF;

	END IF;
		
	FETCH rplanes into person;
	END LOOP;
	close rplanes;
	return resultado;
END;
$function$
