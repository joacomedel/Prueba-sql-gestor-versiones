CREATE OR REPLACE FUNCTION public.datosafiliacion(nrodoc character varying, barra character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	aux RECORD;
	aux2 RECORD;
	aux3 RECORD;
	aux4 RECORD;
	aux5 RECORD;
rtemporal RECORD;

	vbarra int4;
	
	
BEGIN

--Lo busco con la barra que corresponde, sino lo encuentro lo busco sin barra.
SELECT INTO aux * FROM persona
                   WHERE persona.nrodoc = $1
                         AND persona.barra=$2;
IF NOT FOUND THEN
	SELECT INTO aux * FROM persona WHERE persona.nrodoc = $1;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Error 1';
	END IF;
END IF;

--Malapi 25-03-2015 Verifico que exista el campo en la tabla temporal, para que no me de error mientras no se pone en producccion 
--la nueva version de afiliaciones. 
--Malapi 27-03-2015 Modifico pues no sirve para tablas temporales concurrentes. select INTO rtemporal column_name from information_schema.columns where table_name='afiliado' AND column_name = 'nrodocreal';
SELECT  INTO rtemporal attname, format_type(atttypid, atttypmod) AS type
FROM   pg_attribute
WHERE  attrelid = 'afiliado'::regclass
AND    attnum > 0
AND    NOT attisdropped
AND attname = 'nrodocreal'
ORDER  BY attnum;
IF NOT FOUND THEN 
   ALTER TABLE afiliado ADD COLUMN nrodocreal text;
   UPDATE afiliado SET nrodocreal = aux.nrodoc;
  
END IF;


--En este punto ya tengo los datos de persona en aux.
--    vbarra = aux.barra; LO COMENTE PORQUE LA BARRA QUE TIENE EN PERSONA NO SIEMPRE ES LA QUE
--NECESITO, POR EJ, SI SE QUIERE Q UN BENEFICIARIO SEA AHORA UN TITULAR SE DESEA QUE LAS VERIFICACIONES
--LAS REALICE CON LA BARRA QUE SE LE MANDA POR PARAMETRO NO CON LA QUE TIENE EN LA TABLA PERSONA
    vbarra = $2;
    SELECT INTO aux3 * FROM direccion WHERE direccion.iddireccion=aux.iddireccion and direccion.idcentrodireccion= aux.idcentrodireccion;
	INSERT INTO afiliado(nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos,iddireccion,
idcentrodireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad,tipodoc,carct,barra,nrodocreal) 
    VALUES(aux.nrodoc,aux.apellido,aux.nombres,aux.fechanac,aux.sexo,aux.estcivil,aux.telefono,aux.email,aux.fechainios,aux.fechafinos,aux.iddireccion, aux.idcentrodireccion,aux3.barrio,aux3.calle,aux3.nro,aux3.tira,aux3.piso,aux3.dpto,aux3.idprovincia,aux3.idlocalidad,aux.tipodoc,aux.carct,aux.barra,aux.nrodocreal);

IF (vbarra > 129) AND (vbarra < 200) THEN
				SELECT INTO aux * FROM afilreci WHERE afilreci.nrodoc=$1
                                                     AND afilreci.barra=vbarra;
				IF FOUND THEN
					SELECT INTO aux4 * FROM estados WHERE estados.idestado=aux.idestado;
					SELECT INTO aux3 * FROM osreci WHERE osreci.idosreci = aux.idosreci;
					SELECT INTO aux2 * FROM reciprocidades WHERE reciprocidades.idreci = aux.idreci;
					UPDATE afiliado SET idestado=aux.idestado, estado=aux4.descrip, fechavtoreci=aux.fechavtoreci,reciprocidades=aux2.descrip,idreci= aux2.idreci, idosreci = aux3.idosreci, osreci=aux3.descrip
					                WHERE afiliado.nrodoc = aux.nrodoc;	
				ELSE 	SELECT INTO aux * FROM benefreci WHERE benefreci.nrodoc=$1;

                    IF FOUND THEN
                       	SELECT INTO aux5 * FROM afilreci WHERE afilreci.nrodoc=aux.nrodoctitu;			
				    	SELECT INTO aux4 * FROM estados WHERE estados.idestado=aux.idestado;
				     	SELECT INTO aux3 * FROM osreci WHERE osreci.idosreci = aux5.idosreci;
				      	SELECT INTO aux2 * FROM reciprocidades WHERE reciprocidades.idreci = aux.idreci;
				       	UPDATE afiliado SET idestado=aux.idestado, estado=aux4.descrip, fechavtoreci=aux.fechavtoreci,reciprocidades=aux2.descrip,idreci= aux2.idreci, idosreci = aux3.idosreci, osreci=aux3.descrip
					                WHERE afiliado.nrodoc = aux.nrodoc;	
                    else
                    	RAISE EXCEPTION 'El afiliado buscado existe en la Tabla Persona pero no existe en la tabla de reciprocidad';
                   	END IF;
           		END IF;
				
	END IF;
 IF vbarra > 29 AND vbarra < 100 THEN
		
		SELECT INTO aux * FROM afilsosunc WHERE afilsosunc.nrodoc = $1 AND afilsosunc.barra = vbarra;
			IF FOUND THEN
					SELECT INTO aux2 * FROM estados WHERE idestado=aux.idestado;
				SELECT INTO aux4 * FROM osexterna WHERE osexterna.idosexterna = aux.idosexterna;
				UPDATE afiliado SET idestado=aux2.idestado, estado=aux2.descrip, nrocuilini=aux.nrocuilini, nrocuildni=aux.nrocuildni, nrocuilfin=aux.nrocuilfin, nroosexterna=aux.nroosexterna, idosexterna=aux.idosexterna, idctacte=aux.idctacte, osexterna = aux4.descrip
								WHERE afiliado.nrodoc = $1 AND afiliado.barra = vbarra;
				IF vbarra = 30 THEN
					SELECT INTO aux * FROM afilidoc WHERE afilidoc.nrodoc=$1;
					IF FOUND THEN
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					 END IF;
				END IF;
			
				IF vbarra = 31 THEN
					SELECT INTO aux * FROM afilinodoc WHERE afilinodoc.nrodoc=$1;
					IF FOUND THEN
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF vbarra = 32 THEN
					SELECT INTO aux * FROM afilisos WHERE afilisos.nrodoc=$1;
					IF FOUND THEN
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF vbarra = 33 THEN
					IF FOUND THEN
						SELECT INTO aux * FROM afilirecurprop WHERE afilirecurprop.nrodoc=$1;
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF vbarra = 34 THEN
					SELECT INTO aux * FROM afilibec WHERE afilibec.nrodoc=$1;
					IF FOUND THEN
						UPDATE afiliado SET idresolbec=aux.idresolbe
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF vbarra = 35 THEN
					SELECT INTO aux * FROM afiljub WHERE afiljub.nrodoc=$1;
					IF FOUND THEN
						UPDATE afiliado SET idcertpers=aux.idcertpers, trabaja=aux.trabaja, trabajaunc=aux.trabajaunc,ingreso=aux.ingreso
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF vbarra = 36 THEN
					SELECT INTO aux * FROM afilpen WHERE afilpen.nrodoc=$1;
					IF FOUND THEN
						SELECT INTO aux2 * FROM tiposdoc WHERE tiposdoc.tipodoc = aux.tipodoctitu;
						UPDATE afiliado SET nrodocjub=aux.nrodoctitu,trabaja=aux.trabaja, tipodocjub=aux.tipodoctitu,ingreso=aux.ingreso,tipodocjubides= aux2.descrip
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF vbarra = 37 THEN
					IF FOUND THEN
						SELECT INTO aux * FROM afiliauto WHERE afiliauto.nrodoc=$1;
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				
			ELSE 	
            	SELECT INTO aux * FROM afilsosunc WHERE afilsosunc.nrodoc = $1;
			    IF FOUND THEN
					SELECT INTO aux2 * FROM estados WHERE idestado=aux.idestado;
				   SELECT INTO aux4 * FROM osexterna WHERE osexterna.idosexterna = aux.idosexterna;
				   UPDATE afiliado SET idestado=aux2.idestado, estado=aux2.descrip, nrocuilini=aux.nrocuilini, nrocuildni=aux.nrocuildni, nrocuilfin=aux.nrocuilfin, nroosexterna=aux.nroosexterna, idosexterna=aux.idosexterna, idctacte=aux.idctacte, osexterna = aux4.descrip
								WHERE afiliado.nrodoc = $1;
		--		ELSE
                	
		--		RAISE EXCEPTION 'El afiliado buscado existe en la Tabla Persona pero no existe en la tabla sosunc';
			    END IF;
            END IF;
    END IF;
RETURN 'true';
END;
$function$
