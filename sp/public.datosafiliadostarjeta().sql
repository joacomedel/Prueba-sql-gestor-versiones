CREATE OR REPLACE FUNCTION public.datosafiliadostarjeta()
 RETURNS SETOF type_datospersonatarjeta
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
   
-- REGISTROS
   rdatostitu RECORD;
   rdatosper RECORD;
   losdatostarjeta RECORD;



--TIPOS
rdatospersona type_datospersonatarjeta;

BEGIN


 IF NOT  iftableexists('afiliado') THEN

  CREATE TEMP TABLE afiliado ( 
  nrodoc varchar NOT NULL,
  apellido varchar NOT NULL,
  nombres varchar NOT NULL,
  fechanac date NOT NULL,
  sexo varchar NOT NULL,
  estcivil varchar NOT NULL,
  telefono varchar,
  email varchar,
  fechainios date NOT NULL,
  fechafinos date NOT NULL,
  iddireccion int NOT NULL,
  idcentrodireccion integer NOT NULL,
  ctacteexpendio boolean, 
  barrio varchar,
  calle varchar,
  nro varchar,
  tira varchar,
  piso varchar,
  dpto varchar,
  idprovincia int,
  idlocalidad int, 
  tipodoc varchar,
  carct varchar,
  barra int,
  fechavtoreci date,
  idosreci int,
  osreci varchar,
  idestado int,
  estado varchar,
  idreci int, 
  reciprocidades varchar,
  nrocuilini varchar,
  nrocuildni varchar,
  nrocuilfin varchar,
  nroosexterna int,
  idosexterna varchar,
  osexterna varchar,
  idctacte int,
  mutu bool,
  nromutu int,
  legajosiu int,
  idcertpers int,
  trabaja bool,
  trabajaunc bool,
  ingreso float,
  nrodocjub varchar,
  tipodocjub int,
  tipodocjubides varchar,
  idresolbec int) WITHOUT OIDS;


 END IF;
 IF NOT  iftableexists('beneficiarios') THEN

 CREATE TEMP TABLE beneficiarios ( 
 nrodoc varchar NOT NULL,
 apellido varchar NOT NULL,
 nombres varchar NOT NULL,
 fechanac date NOT NULL,
 sexo varchar NOT NULL,
 estcivil varchar NOT NULL,
 telefono varchar,
 email varchar,
 fechainios date NOT NULL,
 fechafinos date NOT NULL,
 iddireccion integer NOT NULL,
 idcentrodireccion integer NOT NULL,
 barrio varchar,
 calle varchar,
 nro varchar ,
 tira varchar,
 piso varchar,
 dpto varchar,
 idprovincia integer,
 idlocalidad integer, 
 tipodoc integer NOT NULL,
 carct varchar,
 barra integer,
 fechavtoreci date,
 idestado integer,
 estado varchar,
 idreci integer, 
 reciprocidades varchar,
 nrodoctitu varchar,
 tipodoctitu integer,
 idvin integer,
 barraTitu integer,
 nroosexterna integer,
 idosexterna varchar,
 osexterna varchar,
 mutual boolean,
 barramutu integer,
 nromututitu integer) WITHOUT OIDS;

 END IF;

  SELECT INTO rdatosper * FROM persona 
  JOIN temp_persona AS tp ON (persona.nrodoc=tp.nrodoc AND persona.tipodoc::varchar=tp.tipodoc);
  IF FOUND THEN
        
         IF rdatosper.barra >= 30 THEN 
                 PERFORM datosafiliadov2(rdatosper.nrodoc,rdatosper.barra);
          
         ELSE           
                SELECT INTO rdatostitu * FROM benefsosunc WHERE nrodoc=rdatosper.nrodoc AND tipodoc=rdatosper.tipodoc;
                PERFORM datosbeneficiarios(rdatostitu.nrodoctitu,rdatostitu.tipodoctitu::integer, rdatostitu.barratitu::integer);
                UPDATE temp_persona SET estitular=false;
                PERFORM datosafiliadov2(rdatostitu.nrodoctitu,rdatostitu.barratitu);
         END IF;
       
   -- END IF;
    END IF;

FOR rdatospersona IN
   
    SELECT  nrodoc,    apellido,    nombres,    fechanac ,
    sexo ,   estcivil ,    telefono,    email ,   fechainios ,    fechafinos , iddireccion ,
    idcentrodireccion , null as ctacteexpendio ,barrio,   calle ,    nro ,tira,    
    piso,dpto,idprovincia ,idlocalidad , tipodoc    ,
    carct,barra ,fechavtoreci,null as  idosreci ,
    null as osreci ,idestado,estado ,    idreci,
    reciprocidades, null as nrocuilini, null as nrocuildni ,
    null as nrocuilfin,    nroosexterna ,    idosexterna ,
    osexterna , null as  idctacte , 
     null as nromutu ,   null as  legajosiu ,   null as  idcertpers ,
    null as trabaja ,   null as  trabajaunc ,  null as   ingreso,
     null as nrodocjub ,   null as  tipodocjub ,  null as   tipodocjubides,
     null as idresolbec ,    nrodoctitu ,    tipodoctitu ,
     idvin ,    barratitu ,    mutual ,    barramutu ,    nromututitu
     FROM beneficiarios 
     WHERE nrodoc=rdatosper.nrodoc AND tipodoc= rdatosper.tipodoc
    --JOIN temp_persona AS tp 
	-- ON (beneficiarios.nrodoc=tp.nrodoc AND beneficiarios.tipodoc::varchar=tp.tipodoc)
     UNION 
     
     SELECT   nrodoc,    apellido,    nombres,    fechanac ,
    sexo ,   estcivil ,    telefono,   email ,   fechainios ,    fechafinos ,    iddireccion,
    idcentrodireccion, ctacteexpendio,barrio,    calle ,    nro ,    tira,    piso  ,
    dpto,    idprovincia ,    idlocalidad ,    tipodoc::int,
    carct,    barra ,    fechavtoreci ,    idosreci ,
    osreci ,    idestado ,    estado ,    idreci ,
    reciprocidades,    nrocuilini,    nrocuildni ,
    nrocuilfin,    nroosexterna ,    idosexterna ,
    osexterna ,    idctacte ,   
    nromutu ,    legajosiu ,    idcertpers ,
    trabaja ,    trabajaunc ,    ingreso,
    nrodocjub ,    tipodocjub ,    tipodocjubides,
    idresolbec ,  null as  nrodoctitu ,  null as  tipodoctitu ,
    null as idvin ,    null as barratitu , null as   mutual , null as  barramutu ,
    null as nromututitu 
   
     FROM afiliado  
     

 LOOP

return next rdatospersona;

     
end loop;


END;
$function$
