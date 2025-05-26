CREATE OR REPLACE FUNCTION public.agregarpersonaplanes(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    	person RECORD;
	plancobpers RECORD;
	resultado boolean;
	edad int4;
	nrodocu alias for $1;
	tipodocu alias for $2;

BEGIN
	resultado = true;
/*
MaLaPi 21-03-2018 Pongo en produccion el SP que genera los movimientos de planes de coberturas usando una tabla de configuracion
*/

SELECT INTO resultado * FROM agregarpersonaplanes_contabla(nrodocu,tipodocu);
--MaLaPi 24-08-2018 Tambien lo dejo en sys_agregarplanescobertura_diario() para dar de baja los planes de coberturas automaticos diariamente
-- MaLaPi 21-03-2018 Genera las bolsas de practicas de pre-auditoria.
--SELECT INTO resultado * FROM alta_modifica_auditoria_medica_pendientes_automaticos(nrodocu,tipodocu);
--MaLaPi 24-08-2018 Lo comento de aqui.... lo coloco en sys_agregarplanescobertura_mensual() para que se corra los primeros dias del mes.
/*
SELECT INTO person * FROM persona WHERE persona.nrodoc =  nrodocu AND persona.tipodoc = tipodocu;

	IF (person.barra < 100 )THEN 
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 1;
		
		IF NOT FOUND THEN 
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN GENERAL
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('1',person.nrodoc,person.tipodoc,1,CURRENT_DATE);

		END IF;

		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 35;
		
		IF NOT FOUND THEN 
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN 35-ESPECIAL EN RECIPROCIDAD
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('35',person.nrodoc,person.tipodoc,35,CURRENT_DATE);

		END IF;

		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 34;
		
		IF NOT FOUND THEN 
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN 34 - GENERAL EN RECIPROCIDAD
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('34',person.nrodoc,person.tipodoc,34,CURRENT_DATE);

		END IF;

                SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 38;
  
                IF NOT FOUND THEN 
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN FARMACIA SOSUNC
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('38',person.nrodoc,person.tipodoc,38,CURRENT_DATE);

		END IF;

	END IF; 	

	IF ((person.barra < 100 ) 
		AND person.sexo = 'F' 
		AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 18) THEN 
		
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 5;
		
		IF NOT FOUND THEN
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN PREVENTIVO CANCER DE MAMA/UTERO
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('5',person.nrodoc,person.tipodoc,5,CURRENT_DATE);

		END IF; 
                IF extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 35 THEN
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN PREVENTIVO DE CANCER DE MAMA (39)

                SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 39;
		
		IF NOT FOUND THEN

			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('39',person.nrodoc,person.tipodoc,39,CURRENT_DATE);

		END IF; 
               END IF;    

	END IF; 

	IF ((person.barra < 100 ) 
		AND person.sexo = 'M' 
		AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 45)THEN 
		
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 4;
		
		IF NOT FOUND THEN
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN PREVENTIVO CANCER DE PROSTATA
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('4',person.nrodoc,person.tipodoc,4,CURRENT_DATE);

		END IF;

	END IF;

	IF ((person.barra < 100 AND person.barra > 29) OR (person.barra > 129) 
		AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 18)THEN 
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN OPTICA AFILIADOS		
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 8;
		
		IF NOT FOUND THEN

			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('8',person.nrodoc,person.tipodoc,8,CURRENT_DATE);

		END IF;

	END IF;       

	IF ((person.barra > 100 AND person.barra < 129) OR (person.barra < 29) 
		AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 18)THEN 
		
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 9;
		
		IF NOT FOUND THEN
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN OPTICA BENEFICIARIOS
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('9',person.nrodoc,person.tipodoc,9,CURRENT_DATE);

		END IF;

             

	END IF;


	IF (extract(year FROM age(CURRENT_DATE,person.fechanac)) <= 18)THEN 
		
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 10;
		
		IF NOT FOUND THEN
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN OPTICA MENORES
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('10',person.nrodoc,person.tipodoc,10,CURRENT_DATE);
		END IF;
	END IF;

	IF (extract(year FROM age(CURRENT_DATE,person.fechanac)) <= 18
            AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 13)THEN 
		
		SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		AND tipodoc = person.tipodoc AND idplancoberturas = 36;
		
		IF NOT FOUND THEN
-- INSERTAR AFILIADOS DE SOSUNC AL PLAN 36-ORTODONCIA
			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('36',person.nrodoc,person.tipodoc,36,CURRENT_DATE);
		END IF;
	END IF;

	IF person.barra = 149 or person.barra = 131 THEN 
			SELECT INTO plancobpers *  
			 FROM plancobpersona WHERE nrodoc = person.nrodoc 
			AND tipodoc = person.tipodoc AND idplancoberturas = 29;
		
			IF NOT FOUND THEN
-- 05-09-2016 MALAPI: LAS BARRAS 149 Y 131 NO TIENEN MAS EL PLAN DE RECIPROCIDAD USAN EL DE RECIPROCIDAD CON COSEGURO
-- INSERTAR BENEFICIARIOS DE DASUTEN AL PLAN 29 -DASUTEN 	
				INSERT INTO plancobpersona 
				(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
				VALUES
				('29',person.nrodoc,person.tipodoc,29,CURRENT_DATE);
			
			END IF;
	END IF;
SELECT INTO person * FROM persona NATURAL JOIN  afilreci
WHERE persona.nrodoc =  nrodocu AND persona.tipodoc = tipodocu;

	IF FOUND THEN
-- 05-09-2016 MALAPI: LAS BARRAS 149 Y 131 NO TIENEN MAS EL PLAN DE RECIPROCIDAD USAN EL DE RECIPROCIDAD CON COSEGURO
		IF (person.barra > 100 AND (person.barra <> 149 OR person.barra <> 131) )THEN 

			SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
			AND tipodoc = person.tipodoc AND idplancoberturas = 12;
		
			IF NOT FOUND THEN
-- INSERTAR AFILIADOS DE RECIPROCIDAD AL PLAN RECIPROCIDAD
				INSERT INTO plancobpersona 
				(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
				VALUES
				('12',person.nrodoc,person.tipodoc,12,CURRENT_DATE);

			END IF;

		END IF;


	END IF; 


SELECT INTO person * FROM persona NATURAL JOIN  benefreci
WHERE persona.nrodoc =  nrodocu AND persona.tipodoc = tipodocu;

	IF FOUND THEN
-- 05-09-2016 MALAPI: LAS BARRAS 149 Y 131 NO TIENEN MAS EL PLAN DE RECIPROCIDAD USAN EL DE RECIPROCIDAD CON COSEGURO
		IF (person.barra > 100 AND (person.barratitu <> 149 OR person.barratitu <> 131) )THEN 
		
			SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
			AND tipodoc = person.tipodoc AND idplancoberturas = 12;
-- INSERTAR BENEFICIARIOS DE RECIPROCIDAD AL PLAN RECIPROCIDAD
			IF NOT FOUND THEN

				INSERT INTO plancobpersona 
				(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
				VALUES
				('12',person.nrodoc,person.tipodoc,12,CURRENT_DATE);
			
			END IF;

		END IF;
-- 05-09-2016 MALAPI: LAS BARRAS 149 Y 131 NO TIENEN MAS EL PLAN DE RECIPROCIDAD USAN EL DE RECIPROCIDAD CON COSEGURO
		IF (person.barratitu = 149 or person.barratitu = 131)THEN 

			SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
			AND tipodoc = person.tipodoc AND idplancoberturas = 29;
		
			IF NOT FOUND THEN
-- INSERTAR BENEFICIARIOS DE DASUTEN AL PLAN 29 -DASUTEN 	
				INSERT INTO plancobpersona 
				(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
				VALUES
				('29',person.nrodoc,person.tipodoc,29,CURRENT_DATE);
			
			END IF;

		END IF;

		IF ((person.barratitu = 149) 
			AND person.sexo = 'F' 
			AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 18)THEN 

			SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
			AND tipodoc = person.tipodoc AND idplancoberturas = 5;
		
			IF NOT FOUND THEN
-- INSERTAR BENEFICIARIOS DE DASUTEN AL PLAN PREVENTIVO CANCER MAMA/UTERO
				INSERT INTO plancobpersona 
				(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
				VALUES
				('5',person.nrodoc,person.tipodoc,5,CURRENT_DATE);
			
			END IF;

                        IF extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 35 THEN
                        -- INSERTAR AFILIADOS DE SOSUNC AL PLAN PREVENTIVO DE CANCER DE MAMA (39)

                        SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
		        AND tipodoc = person.tipodoc AND idplancoberturas = 39;
		
		IF NOT FOUND THEN

			INSERT INTO plancobpersona 
			(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
			VALUES
			('39',person.nrodoc,person.tipodoc,39,CURRENT_DATE);

		END IF; 
               END IF;   


		END IF;

		IF ((person.barratitu = 149) 
			AND person.sexo = 'M' 
			AND extract(year FROM age(CURRENT_DATE,person.fechanac)) >= 45)THEN 
-- INSERTAR BENEFICIARIOS DE DASUTEN AL PLAN PREVENTIVO CANCER PROSTATA
			SELECT INTO plancobpers * FROM plancobpersona WHERE nrodoc = person.nrodoc 
			AND tipodoc = person.tipodoc AND idplancoberturas = 4;
		
			IF NOT FOUND THEN
		
				INSERT INTO plancobpersona 
				(idplancobertura,nrodoc,tipodoc,idplancoberturas,pcpfechaingreso)
				VALUES
				('4',person.nrodoc,person.tipodoc,4,CURRENT_DATE);
			
			END IF;

		END IF;


	END IF; 

SELECT INTO person * FROM persona WHERE persona.nrodoc =  nrodocu AND persona.tipodoc = tipodocu;

edad = extract(year FROM age(CURRENT_DATE,person.fechanac));

SELECT INTO plancobpers * FROM plancobpersona 
	WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 10;

IF (FOUND AND edad > 18) THEN
-- BORRAR PERSONAS DEL PLAN OPTICA MENORES
	DELETE FROM plancobpersona WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 10;		 
			
END IF;



SELECT INTO plancobpers * FROM plancobpersona 
	WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 1;

IF (FOUND AND person.barra > 99 ) THEN
-- BORRAR PERSONAS RECIPROCIDAD DEL PLAN GENERAL, DASUTEN YA TIENE SU PROPIO PLAN
	DELETE FROM plancobpersona WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 1;		 
			
END IF;

SELECT INTO plancobpers * FROM plancobpersona 
	WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 36;

IF (FOUND AND edad > 19 AND edad < 13) THEN
-- BORRAR PERSONAS DEL PLAN 36 - ORTODONCIA
	DELETE FROM plancobpersona WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 36;		 
			
END IF;

SELECT INTO plancobpers  * FROM plancobpersona 
	WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 6;

IF (FOUND AND CURRENT_DATE > plancobpers.pcpfechaingreso  + integer '300') THEN
-- BORRAR PERSONAS DEL PLAN MATERNO
	DELETE FROM plancobpersona WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 6;
			
END IF;

SELECT INTO plancobpers * FROM plancobpersona 
	WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 7;

IF (FOUND AND CURRENT_DATE > plancobpers.pcpfechaingreso + integer '365') THEN
-- BORRAR PERSONAS DEL PLAN INFANTIL
	DELETE FROM plancobpersona WHERE plancobpersona.nrodoc =  nrodocu 
	AND plancobpersona.tipodoc = tipodocu
	AND plancobpersona.idplancoberturas = 7;
			
END IF;
*/

	return resultado;
END;

$function$
