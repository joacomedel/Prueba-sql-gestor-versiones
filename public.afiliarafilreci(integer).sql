CREATE OR REPLACE FUNCTION public.afiliarafilreci(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	barrita alias for $1;
	direcBD RECORD;
	direcT RECORD;
	persoBD RECORD;
        clienteBD RECORD;
	persoT RECORD;
	afilBD RECORD;
	afilT RECORD;
	resultado boolean;
	barrasBD RECORD;
	tbarrasBD RECORD;
	ultimo BIGINT;
	tafilBD RECORD;
        benefreciaux record;
        yainserto BOOLEAN;
   	iddir bigint;




BEGIN

yainserto= false;

SELECT INTO direcT * FROM dire;
--SELECT INTO direcBD * FROM direccion WHERE iddireccion = direcT.iddireccion;
IF  direcT.iddireccion = 0
	then

			INSERT INTO direccion(barrio,
                              calle,
                              nro,
                              tira,
                              piso,
                              dpto,
                              idprovincia,
                              idlocalidad) VALUES(direcT.barrio,direcT.calle,direcT.nro,direcT.tira,direcT.piso,direcT.dpto,direcT.idprovincia,direcT.idlocalidad );

        SELECT currval('direccion_iddireccion_seq') INTO iddir;

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
                iddir= direcT.iddireccion;
END IF;

SELECT INTO persoT * FROM pers;
SELECT INTO afilT * FROM afil;
-- Me fijo si la persona ya existe en la base de datos
SELECT INTO persoBD * FROM persona WHERE nrodoc = persoT.nrodoc;


IF NOT FOUND then --- si la persona no existe en persona no va a existir tampoco en cliente ni en afilreci
      	INSERT INTO persona (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos
        ,iddireccion,idcentrodireccion,tipodoc,carct)
         VALUES(persoT.nrodoc,persoT.apellido,persoT.nombres,persoT.fechanac, persoT.sexo,persoT.estcivil,persoT.telefono,persoT.email,persoT.fechainios,persoT.fechafinos
       ,iddir,centro(),persoT.tipodoc,persoT.carct);
	
 SELECT INTO clienteBD * FROM cliente WHERE nrocliente = persoT.nrodoc; --  AND barra = barrita;
  /*El cliente no Existe*/
    IF NOT FOUND then 
         INSERT INTO cliente(nrocliente,barra,idtipocliente,idcondicioniva,iddireccion,idcentrodireccion,telefono,email,denominacion) VALUES
         (persoT.nrodoc, persoT.tipodoc,1,1,iddir,centro(),persoT.telefono,persoT.email,
              concat (  persoT.apellido,', ',persoT.nombres ));
    END IF;



                INSERT INTO afilreci SELECT * FROM afil;
ELSE  --si existe 
         
           --Verifico que no exista en la BBDD con otros datos claves
           IF (persoBD.tipodoc = persoT.tipodoc AND persoBD.barra = barrita) THEN

                UPDATE persona
		SET
			apellido = persoT.apellido,
			nombres = persoT.nombres,
			fechanac = persoT.fechanac,
			sexo = persoT.sexo,
			estcivil = persoT.estcivil,
			telefono = persoT.telefono,
			email = persoT.email,
			fechainios = persoT.fechainios,
			fechafinos = persoT.fechafinos,
		--	iddireccion = persoT.iddireccion,
		--	idcentrodireccion= persoT.idcentrodireccion,
			carct = persoT.carct	
		WHERE nrodoc = persoT.nrodoc AND tipodoc = persoT.tipodoc;

          ELSE  ---existe en la BBDD con otra barra o nrodoc
                   IF (  persoBD.barra <> barrita) THEN
                        UPDATE persona
		        SET	barra = barrita,
                        fechafinos = persoT.fechafinos
		        WHERE nrodoc = persoT.nrodoc AND tipodoc = persoT.tipodoc;
                   end if;

         

      END IF;

  SELECT INTO benefreciaux * FROM benefreci WHERE nrodoc= persoT.nrodoc and tipodoc =persoT.tipodoc;
                       IF  FOUND then   
                         delete from  benefreci WHERE nrodoc= persoT.nrodoc and tipodoc =persoT.tipodoc;
                       END IF;

   SELECT INTO clienteBD * FROM cliente WHERE nrocliente = persoT.nrodoc and barra=persoT.tipodoc;
         IF NOT FOUND then
      -----  cambie barra por tipodoc hector 
              INSERT INTO cliente(nrocliente,barra,idtipocliente,idcondicioniva,iddireccion,idcentrodireccion,telefono,email,denominacion) VALUES
       (persoT.nrodoc,persoT.tipodoc,1,1,persoT.iddireccion,persoT.idcentrodireccion,persoT.telefono,persoT.email
        ,   concat ( persoT.apellido,', ',persoT.nombres));
        ELSE
      --Verifico que no exista en la BBDD con otros datos claves
           DELETE FROM cliente WHERE nrocliente=persoT.nrodoc AND barra>=100;  
         /*  IF (clienteBD.barra = barrita) THEN

		UPDATE cliente
		SET
			nrocliente = persoT.nrodoc,
                        barra = personaT.tipodoc,
  			telefono = persoT.telefono,
			email = persoT.email
            --,
		--	iddireccion = persoT.iddireccion,
		 --   idcentrodireccion = persoT.idcentrodireccion
		WHERE nrocliente = persoT.nrodoc;
           ELSE
              ---existe en la BBDD con otra barra o nrodoc
               IF NOT(yainserto) THEN

           

      UPDATE cliente
		SET
			nrocliente = persoT.nrodoc,
                     barra = persoT.tipodoc,
                       
			telefono = persoT.telefono,
			email = persoT.email
            --,
		--	iddireccion = persoT.iddireccion,
		 --   idcentrodireccion = persoT.idcentrodireccion
		WHERE nrocliente = persoT.nrodoc;

               END IF;
         
         
    END IF;
      */
          SELECT INTO afilBD * FROM afilreci WHERE  nrodoc = afilT.nrodoc;
          IF NOT FOUND then
                 INSERT INTO afilreci(barra,tipodoc,idreci,idestado,idosreci,nrodoc,fechavtoreci) VALUES
       (barrita,afilT.tipodoc,afilT.idreci,afilT.idestado,afilT.idosreci,persoT.nrodoc,afilT.fechavtoreci);
	  ELSE          
            --Verifico que no exista en la BBDD con otros datos claves
           IF (afilBD.tipodoc = afilT.tipodoc AND afilBD.barra = barrita) THEN

		UPDATE afilreci
		SET
			fechavtoreci = afilT.fechavtoreci,
			idosreci = afilT.idosreci,			
			idestado = afilT.idestado,
			idreci = afilT.idreci
		WHERE nrodoc = afilT.nrodoc AND tipodoc = afilT.tipodoc;
           ELSE 
                ---existe en la BBDD con otra barra o nrodoc
                IF NOT(yainserto) THEN
                  INSERT INTO tablaerroresUtn(nrodoc, tipodoc, apellido, fechanac, estcivil, fechavigencia,sexo,barra,observacion)
                VALUES (persoT.nrodoc, persoT.tipodoc,persoT.apellido,persoT.fechanac,persoT.estcivil,persoT.fechafinos, persoT.sexo,persoBD.barra,'"Ya existe el afiliado, error con la barra de la persona o tipo documento (3)"');
               END IF;
           END IF;    
  
END IF;


END IF;
END IF;


SELECT INTO barrasBD * FROM barras WHERE barra = barrita AND persoT.tipodoc = tipodoc AND persoT.nrodoc = nrodoc;
IF NOT FOUND then
		INSERT INTO barras VALUES (barrita,1,persoT.tipodoc,persoT.nrodoc);
End IF;

SELECT INTO tbarrasBD * FROM tbarras WHERE  nrodoctitu = afilT.nrodoc AND tipodoctitu = afilT.tipodoc;
IF NOT FOUND
	then
		INSERT INTO tbarras VALUES (afilT.nrodoc,afilT.tipodoc,2);
	else
		UPDATE tbarras
		SET
			nrodoctitu = afilT.nrodoc,
			tipodoctitu = afilT.tipodoc
			--siguiente = 2 el siguiente se mantiene como estaba!!!
		WHERE nrodoctitu = afilT.nrodoc AND tipodoctitu = afilT.tipodoc;
END IF;
SELECT INTO tafilBD * FROM tafiliado WHERE persoT.tipodoc = tipodoc AND persoT.nrodoc = nrodoc ;

IF NOT FOUND
	then
		INSERT INTO tafiliado VALUES (false,persoT.nrodoc,persoT.tipodoc,null,barrita,null,'','','',persoT.nrodoc);
	
else
        if  (tafilBD.benef) then  --esta pero como beneficiario
        UPDATE tafiliado 
		SET
			benef= false,
			tipoafil= tafilBD.nrodoc
			
		WHERE nrodoc  = tafilBD.nrodoc AND tipodoc = tafilBD.tipodoc;
        END IF;

END IF;

SELECT INTO resultado * FROM tratardiscapacidadesbenef();

return resultado;

END;
$function$
