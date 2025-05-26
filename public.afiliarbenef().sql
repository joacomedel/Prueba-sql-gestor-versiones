CREATE OR REPLACE FUNCTION public.afiliarbenef()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	direcBD RECORD;
	direcT RECORD;
	persoBD RECORD;
	persoT RECORD;
	benefBD RECORD;
	benefT RECORD;
	titular RECORD;
	resultado1 boolean;
	resultado2 boolean;
	resultado boolean;
	ultimo BIGINT;	
	estado integer;
	barra integer;
	iddir bigint;
       idcentrodir  bigint;
	elbenefborrado record;
	
BEGIN

SELECT INTO direcT * FROM dire;
--SELECT INTO direcBD * FROM direccion WHERE iddireccion = direcT.iddireccion;
IF  direcT.iddireccion = 0 OR nullvalue(direcT.iddireccion) then  /*La direccion es nueva xq la persona no existe en la BBDD*/
	/*	SELECT INTO ultimo MAX(iddireccion) 1 from direccion; 	
		UPDATE dire SET iddireccion = ultimo WHERE iddireccion = 0;
		UPDATE pers SET iddireccion = ultimo WHERE iddireccion = 0;*/
			INSERT INTO direccion(barrio,
                              calle,
                              nro,
                              tira,
                              piso,
                              dpto,
                              idprovincia,
                              idlocalidad) VALUES(direcT.barrio,direcT.calle,direcT.nro,direcT.tira,direcT.piso,direcT.dpto,direcT.idprovincia,direcT.idlocalidad );

        SELECT currval('direccion_iddireccion_seq') INTO iddir;
         /*DAni agrego el 04072024*/
       select  into idcentrodir centro();
	else
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
               --BelenA 18/06/24 agrego:
               idcentrodir = direcT.idcentrodireccion;
END IF;

SELECT INTO persoT * FROM pers;
SELECT INTO benefT * FROM bene;
SELECT INTO persoBD * FROM persona WHERE nrodoc = persoT.nrodoc AND tipodoc = persoT.tipodoc;
IF NOT FOUND
	then
		SELECT INTO estado idestado FROM afilsosunc WHERE nrodoc = benefT.nrodoctitu AND tipodoc = benefT.tipodoctitu;
		UPDATE bene SET idestado = estado WHERE nrodoc =persoT.nrodoc AND tipodoc = persoT.tipodoc;
	--	INSERT INTO persona SELECT * FROM pers;
      	INSERT INTO persona (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos
        ,iddireccion,idcentrodireccion,tipodoc,carct)
         VALUES(persoT.nrodoc,persoT.apellido,persoT.nombres,persoT.fechanac, persoT.sexo,persoT.estcivil,persoT.telefono,persoT.email,persoT.fechainios,persoT.fechafinos
       ,iddir,/*centro() dani reemplazo03072024 */idcentrodir,persoT.tipodoc,persoT.carct);
	else
	    IF nullvalue(iddir) THEN
	       iddir =persoT.iddireccion;
               idcentrodir =persoT.idcentrodireccion;
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
	 		-- BelenA 18/06/24, cambio porque si la direccion ya existe no le puede poner centro de la delegacion --idcentrodireccion= centro(),
	 		idcentrodireccion= idcentrodir,
                          /*Dani modifico 2205*/
                        /* idcentrodireccion= persoT.idcentrodireccion,*/
			tipodoc = persoT.tipodoc,
			carct = persoT.carct	
		WHERE nrodoc = persoT.nrodoc AND tipodoc = persoT.tipodoc;
END IF;

--SELECT INTO resultado1 * FROM insertarbarra();

SELECT INTO benefBD * FROM benefsosunc WHERE  nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;

IF NOT FOUND
	then
		/*INSERT INTO benefsosunc SELECT * FROM bene;*/
                    

SELECT INTO benefT * FROM bene;

INSERT INTO benefsosunc (barramutu,nroosexterna,idosexterna,nrodoc,mutual,nrodoctitu,nromututitu,idestado,tipodoc,tipodoctitu,idvin,estaactivo)
             VALUES (benefT.barramutu,benefT.nroosexterna,benefT.idosexterna,benefT.nrodoc,benefT.mutual,benefT.nrodoctitu,benefT.nromututitu,benefT.idestado,benefT.tipodoc,benefT.tipodoctitu,benefT.idvin,'TRUE');

	else
		UPDATE benefsosunc
		SET
			barramutu = benefT.barramutu,	
			nroosexterna = benefT.nroosexterna,
			idosexterna = benefT.idosexterna,
			nrodoc = benefT.nrodoc,
			mutual = benefT.mutual,	
			nrodoctitu = benefT.nrodoctitu,
			nromututitu = benefT.nromututitu,
			idestado = benefT.idestado,
			tipodoc = benefT.tipodoc,
			tipodoctitu = benefT.tipodoctitu,
			idvin = benefT.idvin,
                        estaactivo = 'TRUE'
		WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
END IF;
SELECT INTO titular * FROM persona WHERE persona.nrodoc = benefT.nrodoctitu AND tipodoc = benefT.tipodoctitu;
IF FOUND THEN
UPDATE benefsosunc SET barratitu = titular.barra, estaactivo = 'TRUE' WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
END IF;

SELECT INTO resultado1 * FROM insertarbarra();

SELECT INTO resultado2 * FROM tratardiscapacidadesbenef();
 --Igresar Persona Plan si corresponde
    SELECT INTO resultado * FROM ingresarpersonaplan(benefT.nrodoc,benefT.tipodoctitu,null,now()::date);

/*Si la persona es un beneficiario y ha sido borrado y esta siendo nuevamente afiliado debe eliminarse de borrados*/
SELECT INTO elbenefborrado * FROM beneficiariosborrados WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
IF FOUND THEN
  		 DELETE FROM  beneficiariosborrados WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
END IF ;

return resultado1;

END;
$function$
