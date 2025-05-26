CREATE OR REPLACE FUNCTION public.sys_importarprestadoresmasivo()
 RETURNS void
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES    

--REGISTROS
runo RECORD;
rverifica RECORD;

--CURSORES
cprestadores CURSOR for select  trim(ipcuil) as pcuitsinguiones,trim(concat(substring(ipcuil,1,2),'-',substring(ipcuil,3,8),'-',substring(ipcuil,11,1))) as cuitconguiones,ipnombrefantasia,ipmatriculaprovincial::integer,ipalcancematricula
			from importarprestador
			LEFT JOIN prestador ON (replace(pcuit,'-','') = ipcuil OR idprestador = ipcuil)
			WHERE nullvalue(prestador.pcuit); 

BEGIN

CREATE TEMP  TABLE tempprestador (		idprestador bigint NOT NULL,		idmultivac INTEGER,		pdireccion VARCHAR,		ptelefono VARCHAR,		pdomiciliolegal VARCHAR,		pcuit VARCHAR,		pseguro BOOLEAN,		pvtopoliza DATE,		pfechavtornp DATE,		pnroregpretadores INTEGER,		pdescripcion VARCHAR,		idcolegio INTEGER,		pfax VARCHAR,		pemail VARCHAR,		pwww VARCHAR,		pcontacto VARCHAR,		ptelefonomovil VARCHAR,		idcondicioncompra BIGINT,		pmerc BOOLEAN,		pgast BOOLEAN,		pnroiibb VARCHAR,		idtiporetencion BIGINT,		pnombrefantasia VARCHAR,		pesagrupador BOOLEAN,		nrocuentac VARCHAR,		pctabancaria VARCHAR,		pcbu VARCHAR,		idcondicioniva BIGINT,		iddomiciliolegal BIGINT,		iddomicilioreal BIGINT,		pagenteiibb BOOLEAN,		pagenteiva BOOLEAN,		pagenteganancias BOOLEAN,		pcategoria VARCHAR,		diaspago INTEGER,		pobservacion VARCHAR) ;
CREATE TEMP TABLE tempmatricula (					nromatricula INTEGER NOT NULL,					malcance VARCHAR NOT NULL,					idprestador bigint NOT NULL,					mespecialidad VARCHAR NOT NULL) ;
CREATE TEMP TABLE tempdireccion (				iddireccion BIGINT NOT NULL,				tipo VARCHAR(1) NOT NULL,				barrio VARCHAR,				calle VARCHAR NOT NULL,				nro INTEGER NOT NULL,				tira VARCHAR,				piso VARCHAR(5),				dpto VARCHAR(5),				idprovincia BIGINT NOT NULL,				idlocalidad BIGINT NOT NULL) ;
CREATE TEMP TABLE tempcuentas (nrocuenta BIGINT NOT NULL,										tipocuenta SMALLINT NOT NULL,										nrobanco INTEGER NOT NULL,										nrosucursal BIGINT NOT NULL,										digitoverificador SMALLINT,										nrodoc VARCHAR NOT NULL,										tipodoc INTEGER NOT NULL,										cbuini VARCHAR,										cbufin VARCHAR,										cemail VARCHAR) ;
CREATE TEMP TABLE tempprestadortiporetencion (idprestador BIGINT NOT NULL,	idtiporetencion INTEGER NOT NULL) ;
CREATE TEMP TABLE tempprestadorconfig (idprestador BIGINT NOT NULL,	pcgastodirosu BOOLEAN, pcgastodirfarm  BOOLEAN) ;



     OPEN cprestadores;
     FETCH cprestadores INTO runo;

     WHILE FOUND LOOP

	DELETE FROM tempprestador;DELETE FROM tempmatricula;DELETE FROM tempdireccion;DELETE FROM tempcuentas;DELETE FROM tempprestadortiporetencion;

	insert into tempprestador(idprestador,idmultivac,ptelefono,pcuit,pdescripcion,idcolegio,pfax,pemail,pwww,pcontacto,ptelefonomovil,idcondicioncompra,pmerc,pgast,pnroiibb, idcondicioniva,pnombrefantasia,pesagrupador,nrocuentac,pagenteiibb,pagenteiva,pagenteganancias,pcategoria,diaspago,pobservacion)			
	VALUES (0,0,NULL,runo.cuitconguiones,runo.ipnombrefantasia,NULL,NULL,NULL,NULL,NULL,NULL,3,TRUE,FALSE,NULL,3,runo.ipnombrefantasia,FALSE,'20302',FALSE,FALSE,FALSE,'A',30,NULL);
	insert into tempdireccion (iddireccion,tipo,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad) 
	values (0,'l','','',0,'','','',1,1);
	insert into tempdireccion (iddireccion,tipo,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad) 
	values (0,'r','','',0,'','','',1,1);
        IF NOT nullvalue(runo.ipmatriculaprovincial) THEN
		SELECT INTO rverifica * FROM matricula WHERE nromatricula = runo.ipmatriculaprovincial AND  malcance = runo.ipalcancematricula AND mespecialidad = '';
		IF NOT FOUND THEN 
			insert into tempmatricula (idprestador,nromatricula,malcance,mespecialidad) 
			values (0,runo.ipmatriculaprovincial,runo.ipalcancematricula,'');
		END IF;
	END IF;
	insert into tempcuentas (tipocuenta,cemail,cbuini,cbufin,nrobanco,nrosucursal,nrocuenta,digitoverificador,tipodoc,nrodoc) 
	values (0,'','','',0,0,0,0,12,runo.pcuitsinguiones);
        insert into tempprestadorconfig (idprestador,pcgastodirosu,pcgastodirfarm)				values (0,true,false);

	PERFORM public.agregarprestadores();
         

      FETCH cprestadores INTO runo;
      END LOOP;
 
END;
$function$
