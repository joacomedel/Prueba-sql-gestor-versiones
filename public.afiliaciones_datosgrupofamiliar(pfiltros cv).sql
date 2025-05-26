CREATE OR REPLACE FUNCTION public.afiliaciones_datosgrupofamiliar(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	rfiltros RECORD;
	rpersona RECORD;
	rafiliado RECORD;
	nrodoctitular varchar;
	barratitular integer;
        tipodoctitular integer;

	

BEGIN
  EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
  IF NOT  iftableexists('afiliado') THEN
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
  ELSE 
    DELETE  FROM afiliado;
  END IF;

  IF NOT  iftableexists('beneficiarios') THEN
	CREATE TEMP TABLE beneficiarios ( nrodoc varchar(8) NOT NULL,apellido varchar(40) NOT NULL,nombres varchar(50) NOT NULL,fechanac date NOT NULL,sexo varchar(1) NOT NULL,estcivil varchar(15) NOT NULL,telefono varchar,email varchar,fechainios date NOT NULL,fechafinos date NOT NULL,iddireccion int8 NOT NULL,idcentrodireccion integer NOT NULL,barrio varchar,calle varchar(30) NOT NULL,nro int4 NOT NULL,tira varchar(15),piso varchar(10),dpto varchar(5),idprovincia int8 NOT NULL,idlocalidad int8 NOT NULL, tipodoc int2 NOT NULL,carct varchar(6),barra int2,fechavtoreci date,idestado int2,estado varchar(50),idreci int2, reciprocidades varchar(15),nrodoctitu varchar(8),tipodoctitu int2,idvin int2,barraTitu int2,nroosexterna int8,idosexterna varchar(10),osexterna varchar(100),mutual bool,barraMutu int2,nromututitu int8,nrodocreal text ) WITHOUT OIDS;
  ELSE
      DELETE  FROM beneficiarios;
  END IF;
  IF NOT  iftableexists('info_generaluno') THEN
	CREATE TEMP TABLE info_generaluno (nombretitular varchar,nombrebeneficiario varchar, estitular boolean,nrodociniciaproceso varchar,barrainiciaproceso integer , tipodociniciaproceso integer,nrodoctitular varchar,tipodoctitular integer,textoalerta varchar);
  ELSE
      DELETE  FROM info_generaluno;
  END IF;
	--estitular=false, titular=ALVAREZ SANCHEZ, TOMAS, beneficiario=
	-- Primero tengo que identificar si es titular o beneficiario
	 select into rpersona * FROM persona 
				LEFT JOIN (SELECT nrodoctitu,tipodoctitu,nrodoc,tipodoc,barratitu FROM benefsosunc 
					   UNION 
					   SELECT nrodoctitu,tipodoctitu,nrodoc,tipodoc,barratitu FROM benefreci ) as t USING(nrodoc,tipodoc)
					   
				where nrodoc=rfiltros.nrodoc;
	IF FOUND THEN 
		IF (rpersona.barra < 30) 
			OR (rpersona.barra  >= 100 AND rpersona.barra  <= 129)  THEN -- Es un beneficiario 
			nrodoctitular = rpersona.nrodoctitu;
			barratitular =  rpersona.barratitu;
                        tipodoctitular =  rpersona.tipodoctitu;
 
		END IF;
		IF (rpersona.barra >= 30  AND rpersona.barra <= 99) 
			OR (rpersona.barra  >= 130 AND rpersona.barra  <= 199) THEN -- Es un titular 
			nrodoctitular = rpersona.nrodoc;
			barratitular =  rpersona.barra;
                        tipodoctitular =  rpersona.tipodoc;
		END IF;

		PERFORM datosafiliadov2(nrodoctitular,barratitular);
		BEGIN
			PERFORM datosbeneficiarios(nrodoctitular,0,0); -- Los ultimos 2 parametros ya no se usan.
--KR 09-09-21 Elimino de la temporal beneficiarios aquellos beneficiarios que estan pasivos
                        DELETE FROM beneficiarios WHERE idestado=4;
		EXCEPTION 
			WHEN OTHERS THEN
		END;
		
		INSERT INTO info_generaluno (estitular,nrodociniciaproceso,barrainiciaproceso,tipodociniciaproceso,nrodoctitular,tipodoctitular) 
		VALUES((rpersona.nrodoc = nrodoctitular),rpersona.nrodoc,rpersona.barra,rpersona.tipodoc,nrodoctitular,tipodoctitular);
                PERFORM procesaralertaafiliado(nrodoctitular,tipodoctitular);
		IF(rpersona.nrodoc = nrodoctitular) THEN -- El que inicia el proceso es un titular
			UPDATE info_generaluno SET nombretitular = concat(rpersona.apellido,' ',rpersona.nombres),nombrebeneficiario = '';
		ELSE  -- El que inicia el proceso es un beneficiario
			SELECT INTO rafiliado * FROM afiliado;
			UPDATE info_generaluno SET nombretitular = concat(rafiliado.apellido,' ',rafiliado.nombres),nombrebeneficiario = concat(rpersona.apellido,' ',rpersona.nombres);
		END IF;

	ELSE 
		RAISE EXCEPTION 'No existe un afiliado con el Nro. de Documento ingresado.(%)',rfiltros;
	END IF;


RETURN 'true';
END;$function$
