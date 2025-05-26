CREATE OR REPLACE FUNCTION public.afiliarbenefreci()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	direcBD RECORD;
	direcT RECORD;
	persoBD RECORD;
	persoT RECORD;
	benefBD RECORD;
        benefreciaux  RECORD;
	benefT RECORD;
	titular RECORD;
	resultado boolean;
	resultado1 boolean;		
	resultado2 boolean;		
	ultimo integer;	
    yainserto BOOLEAN;
	iddir bigint;
		idcentro bigint;

BEGIN


--SELECT INTO direcT * FROM dire;
yainserto = false;

SELECT INTO direcT * FROM dire;
--SELECT INTO direcBD * FROM direccion WHERE iddireccion = direcT.iddireccion;
IF  direcT.iddireccion = 0 THEN
/*		SELECT INTO ultimo MAX(iddireccion)+1 from direccion; 	
		UPDATE dire SET iddireccion = ultimo WHERE iddireccion = 0;
		UPDATE pers SET iddireccion = ultimo WHERE iddireccion = 0;
		INSERT INTO direccion SELECT * FROM dire;*/
			INSERT INTO direccion(barrio,
                              calle,
                              nro,
                              tira,
                              piso,
                              dpto,
                              idprovincia,
                              idlocalidad) VALUES(direcT.barrio,direcT.calle,direcT.nro,direcT.tira,direcT.piso,direcT.dpto,direcT.idprovincia,direcT.idlocalidad );

        SELECT currval('direccion_iddireccion_seq') INTO iddir;
        idcentro =centro();
	ELSE
		UPDATE direccion
		SET
		--	iddireccion = direcT.iddireccion,
			barrio = direcT.barrio,
			calle = direct.calle,
			nro = direcT.nro,
			tira = direcT.tira,
			piso = direcT.piso,
			dpto = direcT.dpto,
			idprovincia = direcT.idprovincia,
			idlocalidad = direcT.idlocalidad
		WHERE iddireccion = direcT.iddireccion AND idcentrodireccion = direcT.idcentrodireccion;
                iddir = direcT.iddireccion; 
                idcentro =direcT.idcentrodireccion; 
END IF;

SELECT INTO persoT * FROM pers;
SELECT INTO benefT * FROM bene;

-- Me fijo si la persona ya existe en la base de datos
SELECT INTO persoBD * FROM persona WHERE nrodoc = persoT.nrodoc;
IF NOT FOUND THEN

       INSERT INTO persona (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos
       ,iddireccion,idcentrodireccion,tipodoc,carct)
        VALUES(persoT.nrodoc,persoT.apellido,persoT.nombres,persoT.fechanac, persoT.sexo,persoT.estcivil,persoT.telefono,persoT.email,persoT.fechainios,persoT.fechafinos
       ,iddir,idcentro,persoT.tipodoc,persoT.carct);
       /*	UPDATE pers SET idcentrodireccion = centro(),iddireccion=iddir
         WHERE nrodoc =persoT.nrodoc AND tipodoc = persoT.tipodoc;
		INSERT INTO persona SELECT * FROM pers;*/
        INSERT INTO benefreci SELECT * FROM bene;
	ELSE  --si existe
           --Verifico que no exista en la BBDD con otros datos claves
        IF (persoBD.tipodoc = persoT.tipodoc) THEN
	    IF nullvalue(iddir) THEN
	       iddir =persoT.iddireccion;
	       	idcentro = persoT.idcentrodireccion;
        END IF;
		UPDATE persona
		SET
			nrodoc = persoT.nrodoc,
			apellido = persoT.apellido,
			nombres = persoT.nombres,
			fechanac = persoT.fechanac,
			sexo = persoT.sexo,
			estcivil = persoT.estcivil,
			telefono = persoT.telefono,
			email = persoT.email,
			fechainios = persoT.fechainios,
			fechafinos = persoT.fechafinos,
			iddireccion = iddir,
			idcentrodireccion=idcentro,
			tipodoc = persoT.tipodoc,
			carct = persoT.carct	
		WHERE nrodoc = persoT.nrodoc AND tipodoc = persoT.tipodoc;
          ELSE  ---existe en la BBDD con otra barra o nrodoc
                INSERT INTO tablaerroresutn(nrodoc, tipodoc, apellido, fechanac, estcivil, fechavigencia,sexo,barra)
                VALUES (persoT.nrodoc, persoT.tipodoc,persoT.apellido,persoT.fechanac,persoT.estcivil,persoT.fechafinos, persoT.sexo,persoBD.barra);
                yainserto = true;
       END IF; -- IF (persoBD.tipodoc = persoT.tipodoc) THEN
       SELECT INTO benefBD * FROM benefreci WHERE  nrodoc = benefT.nrodoc;
       IF FOUND THEN
	   --Verifico que no exista en la BBDD con otros datos claves
           IF (benefBD.tipodoc = benefT.tipodoc) THEN
		UPDATE benefreci
		SET
			nrodoc = benefT.nrodoc,
			fechavtoreci = benefT.fechavtoreci,
			nrodoctitu = benefT.nrodoctitu,
			idestado = benefT.idestado,
			idreci = benefT.idreci,
			tipodoctitu = benefT.tipodoctitu,
			tipodoc = benefT.tipodoc,
			idvin = benefT.idvin
		WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
          ELSE -- IF (benefBD.tipodoc = benefT.tipodoc) THEN
              ---existe en la BBDD con otra barra o nrodoc
                IF NOT(yainserto) THEN
                   INSERT INTO tablaerroresutn(nrodoc, tipodoc, apellido, fechanac, estcivil, fechavigencia,sexo,barra)
                   VALUES (persoT.nrodoc, persoT.tipodoc,persoT.apellido,persoT.fechanac,persoT.estcivil,persoT.fechafinos, persoT.sexo,persoBD.barra);
                END IF;
          END IF; -- IF (benefBD.tipodoc = benefT.tipodoc) THEN
          ELSE -- IF FOUND THEN  No existe en benefreci
                INSERT INTO benefreci SELECT * FROM bene;
         END IF;
END IF;

SELECT INTO titular * FROM persona WHERE persona.nrodoc = benefT.nrodoctitu AND tipodoc = benefT.tipodoctitu;
IF FOUND THEN
UPDATE benefreci SET barratitu = titular.barra WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;


END IF;
--END IF;
--aca iba insertarbarra
SELECT INTO resultado1 * FROM insertarbarra();
SELECT INTO resultado2 * FROM tratardiscapacidadesbenef();
return resultado1;

END;
$function$
