CREATE OR REPLACE FUNCTION public.datosafiliadov2(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	aux RECORD;
	aux2 RECORD;
	aux3 RECORD;
	aux4 RECORD;
        auxhistobarras RECORD;
        au RECORD;
	labarra int4;
	
	
BEGIN





--Lo busco con la barra que corresponde, sino lo encuentro lo busco sin barra.
SELECT INTO aux * FROM persona 
                   WHERE persona.nrodoc = $1 
                         AND persona.barra=$2; 

/*SELECT INTO auxhistobarras * FROM histobarras 
                   WHERE histobarras.nrodoc = $1 
                         order by fechaini desc limit 1; */
IF NOT FOUND THEN
	SELECT INTO aux * FROM persona WHERE persona.nrodoc = $1;
	IF NOT FOUND THEN 
		--RAISE EXCEPTION 'Error 1';
		RAISE EXCEPTION 'La persona ingresada no existe, verifique si desea seguir con el proceso'; --BelenA 13/01/25
	END IF;
END IF;

 IF NOT existecolumtemp('afiliado','nrocuenta') THEN
DROP TABLE afiliado;
CREATE TEMP TABLE afiliado ( nrodoc varchar(8) NOT NULL,apellido varchar(40) NOT NULL,nombres varchar(50) NOT NULL,fechanac date NOT NULL,sexo varchar(1) NOT NULL,estcivil varchar(15) NOT NULL,telefono varchar,email varchar,fechainios date NOT NULL,fechafinos date NOT NULL,iddireccion int8 NOT NULL,idcentrodireccion integer NOT NULL,barrio varchar,calle varchar(50),nro int4,tira varchar(15),piso varchar,dpto varchar,idprovincia int8,idlocalidad int8, tipodoc int2,carct varchar(6),barra int2,fechavtoreci date,idosreci int2,osreci varchar(100),idestado int2,estado varchar(50),idreci int2, reciprocidades varchar(15),nrocuilini varchar(2),nrocuildni varchar(8),nrocuilfin varchar(1),nroosexterna int8,idosexterna varchar,osexterna varchar(50),idctacte int8,mutu bool,nromutu int8,legajosiu int8,idcertpers int8,trabaja bool,trabajaunc bool,ingreso float4,nrodocjub varchar(8),tipodocjub int2,tipodocjubides varchar(5),idresolbec int8,nrodocreal text
, ctacteexpendio text,
nrocuenta  VARCHAR, 
tipocuenta  VARCHAR,
nrobanco  VARCHAR,
nrosucursal  VARCHAR,
digitoverificador  VARCHAR,
cbuini  VARCHAR,
cbufin  VARCHAR,
emailcuenta  VARCHAR,
nrocuentaviejo  VARCHAR,
textoalerta VARCHAR
) ;
--			   ALTER TABLE afiliado ADD COLUMN nrocuenta  VARCHAR;ALTER TABLE afiliado ADD COLUMN tipocuenta  VARCHAR;ALTER TABLE afiliado ADD COLUMN nrobanco  VARCHAR;ALTER TABLE afiliado ADD COLUMN nrosucursal  VARCHAR;ALTER TABLE afiliado ADD COLUMN digitoverificador  VARCHAR;ALTER TABLE afiliado ADD COLUMN cbuini  VARCHAR;ALTER TABLE afiliado ADD COLUMN cbufin  VARCHAR;ALTER TABLE afiliado ADD COLUMN emailcuenta  VARCHAR;ALTER TABLE afiliado ADD COLUMN nrocuentaviejo  VARCHAR;
END IF;


--En este punto ya tengo los datos de persona en aux.
    labarra = aux.barra;
    SELECT INTO aux3 * FROM direccion WHERE direccion.iddireccion=aux.iddireccion AND direccion.idcentrodireccion=aux.idcentrodireccion;
	INSERT INTO afiliado (nrodoc,apellido,nombres,fechanac,sexo,estcivil,telefono,email,fechainios,fechafinos,iddireccion,idcentrodireccion,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad,tipodoc,carct,barra)
VALUES(aux.nrodoc,aux.apellido,aux.nombres,aux.fechanac,aux.sexo,aux.estcivil,aux.telefono,aux.email,aux.fechainios,aux.fechafinos,aux.iddireccion,aux.idcentrodireccion,aux3.barrio,aux3.calle,aux3.nro,aux3.tira,aux3.piso,aux3.dpto,aux3.idprovincia,aux3.idlocalidad,aux.tipodoc,aux.carct,aux.barra);
IF (labarra > 129) AND (labarra < 200) THEN
				SELECT INTO aux * FROM afilreci WHERE afilreci.nrodoc=$1 
                                                     AND afilreci.barra=labarra; 
				IF FOUND THEN 
					SELECT INTO aux4 * FROM estados WHERE estados.idestado=aux.idestado;
					SELECT INTO aux3 * FROM osreci WHERE osreci.idosreci = aux.idosreci;
					SELECT INTO aux2 * FROM reciprocidades WHERE reciprocidades.idreci = aux.idreci;
					UPDATE afiliado SET idestado=aux.idestado, estado=aux4.descrip, fechavtoreci=aux.fechavtoreci,ctacteexpendio = false,reciprocidades=aux2.descrip,idreci= aux2.idreci, idosreci = aux3.idosreci, osreci=aux3.descrip
					                WHERE afiliado.nrodoc = aux.nrodoc;	
				ELSE 
					RAISE EXCEPTION 'El afiliado buscado existe en la Tabla Persona pero no existe en la tabla de reciprocidad';
				END IF;
				
	END IF;
 IF labarra > 29 AND labarra < 100 THEN 
		
		SELECT INTO aux CASE WHEN nullvalue(btrim(afilsosunc.idosexterna)) OR afilsosunc.idosexterna = 'null'  OR btrim(afilsosunc.idosexterna) = '' THEN '0' ELSE afilsosunc.idosexterna END as idosexterna,* FROM afilsosunc WHERE afilsosunc.nrodoc = $1 AND afilsosunc.barra = labarra;
			IF FOUND THEN
					SELECT INTO aux2 * FROM estados WHERE idestado=aux.idestado; 
				SELECT INTO aux4 * FROM osexterna WHERE osexterna.idosexterna = aux.idosexterna;
				UPDATE afiliado SET idestado=aux2.idestado, estado=aux2.descrip, nrocuilini=aux.nrocuilini, nrocuildni=aux.nrocuildni, nrocuilfin=aux.nrocuilfin, nroosexterna=aux.nroosexterna, idosexterna=aux.idosexterna, idctacte=aux.idctacte, osexterna = aux4.descrip   
								WHERE afiliado.nrodoc = $1 AND afiliado.barra = labarra;
				UPDATE afiliado SET ctacteexpendio = aux.ctacteexpendio WHERE afiliado.nrodoc = $1 AND afiliado.barra = labarra;
				IF labarra = 30 THEN 
					SELECT INTO aux * FROM afilidoc WHERE afilidoc.nrodoc=$1; 
					IF FOUND THEN 
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					 END IF;
				END IF;
			
				IF labarra = 31 THEN 
					SELECT INTO aux * FROM afilinodoc WHERE afilinodoc.nrodoc=$1; 
					IF FOUND THEN 
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF labarra = 32 THEN 
					SELECT INTO aux * FROM afilisos WHERE afilisos.nrodoc=$1; 
					IF FOUND THEN 
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF labarra = 33 THEN 
					IF FOUND THEN 
						SELECT INTO aux * FROM afilirecurprop WHERE afilirecurprop.nrodoc=$1; 
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF labarra = 34 THEN 
					SELECT INTO aux * FROM afilibec WHERE afilibec.nrodoc=$1; 
					IF FOUND THEN 
						UPDATE afiliado SET idresolbec=aux.idresolbe
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF labarra = 35 THEN
					SELECT INTO aux * FROM afiljub WHERE afiljub.nrodoc=$1;
					IF FOUND THEN  
						UPDATE afiliado SET idcertpers=aux.idcertpers, trabaja=aux.trabaja, trabajaunc=aux.trabajaunc,ingreso=aux.ingreso
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF labarra = 36 THEN
					SELECT INTO aux * FROM afilpen WHERE afilpen.nrodoc=$1; 
					IF FOUND THEN 
						SELECT INTO aux2 * FROM tiposdoc WHERE tiposdoc.tipodoc = aux.tipodoctitu;
						UPDATE afiliado SET nrodocjub=aux.nrodoctitu,trabaja=aux.trabaja, tipodocjub=aux.tipodoctitu,ingreso=aux.ingreso,tipodocjubides= aux2.descrip
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
				IF labarra = 37 THEN 
					IF FOUND THEN 
						SELECT INTO aux * FROM afiliauto WHERE afiliauto.nrodoc=$1; 
						UPDATE afiliado SET mutu=aux.mutu, nromutu=aux.nromutu, legajosiu=aux.legajosiu
						                WHERE afiliado.nrodoc = aux.nrodoc;	
					END IF;
				END IF;
                       
                           SELECT INTO au nrocuenta, tipocuenta,nrobanco,nrosucursal,digitoverificador,cbuini,cbufin, email as emailcuenta,concat('nrocuenta:', nrocuenta , 'tipocuenta:' , tipocuenta , 'nrobanco:' , nrobanco , 'nrosucursal:' , nrosucursal , 'digitoverificador:' , digitoverificador , 'cbu:', cbuini ,'-', cbufin) as nrocuentaviejo   
                           FROM cuentas NATURAL JOIN persona                
                           WHERE cuentas.nrodoc= $1; 
                           IF FOUND THEN
                                   UPDATE afiliado SET nrocuenta =au.nrocuenta , tipocuenta = au.tipocuenta,nrobanco=au.nrobanco,nrosucursal=au.nrosucursal,digitoverificador=au.digitoverificador,cbuini=au.cbuini,cbufin=au.cbufin, emailcuenta = au.emailcuenta,nrocuentaviejo = au.nrocuentaviejo
                                   WHERE afiliado.nrodoc = $1; 
                           END IF;
				
			ELSE 				
				RAISE EXCEPTION 'El afiliado buscado existe en la Tabla Persona pero no existe en la tabla sosunc';
			END IF;
    END IF;
    PERFORM procesaralertaafiliado($1,aux.tipodoc);
RETURN 'true';
END;$function$
