CREATE OR REPLACE FUNCTION public.cargarprestadoresdesdeexcel()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
--cursores

cursorprestador refcursor;
cursormatricula refcursor;
cursordireccion refcursor;
cursorcuentas refcursor;


--registros
datoprestador RECORD;
datomatricula RECORD;
datodireccion RECORD;
datocuentas RECORD;


--variables
respuesta boolean;
aux boolean;

BEGIN
CREATE  TABLE tempprestador (
idprestador INTEGER NOT NULL,
idmultivac INTEGER,
pdireccion VARCHAR,
ptelefono VARCHAR,
pdomiciliolegal VARCHAR,
pcuit VARCHAR,
pseguro BOOLEAN,
pvtopoliza DATE,
pfechavtornp DATE,
pnroregpretadores INTEGER,
pdescripcion VARCHAR,
idcolegio INTEGER,
pfax VARCHAR,
pemail VARCHAR,
pwww VARCHAR,
pcontacto VARCHAR,
ptelefonomovil VARCHAR,
idcondicioncompra BIGINT,
pmerc BOOLEAN,
pgast BOOLEAN,
pnroiibb VARCHAR,
idtiporetencion BIGINT,
pnombrefantasia VARCHAR,
pesagrupador BOOLEAN,
nrocuentac VARCHAR,
pctabancaria VARCHAR,
pcbu VARCHAR,
idcondicioniva BIGINT,
iddomiciliolegal BIGINT,
iddomicilioreal BIGINT,
pagenteiibb BOOLEAN,
pagenteiva BOOLEAN,
pagenteganancias BOOLEAN,
pcategoria VARCHAR,
pobservacion VARCHAR) WITHOUT OIDS;





CREATE  TABLE tempmatricula (
nromatricula INTEGER NOT NULL,
malcance VARCHAR NOT NULL,
idprestador INTEGER NOT NULL,
mespecialidad VARCHAR NOT NULL) WITHOUT OIDS;

CREATE  TABLE tempdireccion (
iddireccion BIGINT NOT NULL,
tipo VARCHAR(1) NOT NULL,
barrio VARCHAR,
calle VARCHAR NOT NULL,
nro INTEGER NOT NULL,
tira VARCHAR,
piso VARCHAR(5),
dpto VARCHAR(5),
idprovincia BIGINT NOT NULL,
idlocalidad BIGINT NOT NULL) WITHOUT OIDS;

CREATE  TABLE tempcuentas (nrocuenta BIGINT NOT NULL,
tipocuenta SMALLINT NOT NULL,
nrobanco INTEGER NOT NULL,
nrosucursal BIGINT NOT NULL,
digitoverificador SMALLINT,
nrodoc VARCHAR NOT NULL,
tipodoc INTEGER NOT NULL,
cbuini VARCHAR,
cbufin VARCHAR,
cemail VARCHAR) WITHOUT OIDS;

open cursorprestador for  select * from prestadorpsicologia;

FETCH cursorprestador INTO datoprestador;
WHILE  found  LOOP


DELETE FROM tempprestador;
DELETE FROM tempmatricula;
DELETE FROM tempdireccion;
DELETE FROM tempcuentas;


respuesta = true;



insert into tempprestador (idprestador,idmultivac,ptelefono,pcuit,pdescripcion,idcolegio,pfax,pemail,pwww,pcontacto,ptelefonomovil,idcondicioncompra,                pmerc,pgast,pnroiibb,idtiporetencion,idcondicioniva,pnombrefantasia,pesagrupador,nrocuentac,                pagenteiibb,pagenteiva,pagenteganancias,pcategoria,pobservacion)
VALUES (0,0,datoprestador.telefono,datoprestador.cuit,replace(datoprestador.razonsocial,',',''),NULL,NULL,NULL,NULL,NULL,NULL,3,TRUE,FALSE,NULL ,NULL,3,replace(datoprestador.razonsocial,',',''),FALSE,'20200',FALSE,FALSE,FALSE,'A',NULL);

insert into tempdireccion (iddireccion,tipo,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
 values (0,'l','',datoprestador.calle,123,'','','',1,1);

insert into tempdireccion (iddireccion,tipo,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
values (0,'r','','',0,'','','',1,1);

insert into tempmatricula (idprestador,nromatricula,malcance,mespecialidad)
values (0,datoprestador.matricula,'Rio Negro','Psicologia');

insert into tempcuentas (tipocuenta,cemail,cbuini,cbufin,nrobanco,nrosucursal,nrocuenta,digitoverificador,tipodoc,nrodoc)
values (0,'','','',0,0,0,0,12, replace(datoprestador.cuit,'-',''));



SELECT INTO aux * FROM public.agregarprestadores();

FETCH cursorprestador INTO datoprestador;

END LOOP;
close cursorprestador;

drop table tempprestador;
drop table tempmatricula;
drop table tempdireccion;
drop table tempcuentas;

return respuesta;	
END;
$function$
