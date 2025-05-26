CREATE OR REPLACE FUNCTION public.asentarrecetariotprecibo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
nrortp integer;
resp bigint;
resp1 boolean;
--registros 
rtemporal RECORD;
rrecetariotp RECORD;
BEGIN

 IF NOT iftableexistsparasp('temporden') THEN
	CREATE TEMP TABLE temporden(nrodoc varchar(8),
	tipodoc int  NOT NULL,
	numorden bigint , 
	ctroorden integer,
	centro int4 NOT NULL,
	recibo boolean,
	tipo int8,
	amuc float ,
	afiliado float ,
	sosunc float,
	enctacte boolean,
	idprestador INTEGER,
	ordenreemitida INTEGER,
	centroreemitida INTEGER,
	nromatricula INTEGER,
	cantordenes INTEGER, 
	idasocconv BIGINT,
	nroreintegro BIGINT, 
	anio INTEGER,
        autogestion BOOLEAN,

	idcentroreintegro INTEGER 
        ,formapago varchar
	) WITHOUT OIDS;

    END IF;



 SELECT INTO rtemporal * FROM ttorden;
 IF FOUND THEN 
 INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,
			enctacte,idprestador,ordenreemitida,centroreemitida,
			nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro,autogestion) 
	VALUES(rtemporal.nrodoc,rtemporal.tipodoc,null,null,centro(),rtemporal.tipo,rtemporal.amuc,
       CASE WHEN nullvalue(rtemporal.efectivo) then rtemporal.cuentacorriente else rtemporal.efectivo end,
		(rtemporal.cuentacorriente <> 0),null,null,null,null,rtemporal.cantordenes,rtemporal.idasocconv,null,null,null,false);

 END IF;

IF NOT  iftableexistsparasp('tempitems') THEN

	CREATE TEMP TABLE tempitems(cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4) WITHOUT OIDS;


       INSERT INTO tempitems(cantidad,importe,idplancob,amuc,afiliado,sosunc) 
        (
            SELECT cantordenes,

            (amuc+efectivo+cuentacorriente+sosunc)/cantordenes as importe, 
            idplancobertura,amuc/cantordenes,
            (efectivo+cuentacorriente)/cantordenes as afiliado,
             sosunc/cantordenes 
            FROM ttconsulta              NATURAL JOIN ttorden
       );

  END IF;


IF NOT  iftableexistsparasp('temp_expendioag') THEN

CREATE TEMP TABLE temp_expendioag(cantidad int4 NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,tipo integer,idrecibo integer,centro integer,idpractica varchar,idasocconv bigint,nrodoc varchar,tipodoc integer,idplancobertura integer,accion varchar,textoerror varchar) WITHOUT OIDS;
INSERT INTO temp_expendioag (idplancobertura, nrodoc , tipodoc,cantidad) 
( SELECT idplancobertura::integer, nrodoc , tipodoc,cantordenes 
   FROM ttconsulta
  NATURAL JOIN ttorden
);
  END IF;

    resp = 0;
    resp1 = false;

  /*  SELECT INTO rrecetariotp * FROM temporden;
    FOR nrortp IN 1..rrecetariotp.cantordenes LOOP 
*/
          SELECT * INTO  resp1 FROM generarrecetariotratamientoprolongado();
         
 --   END LOOP;

    if (resp1) then
       select * into resp
              from asentarreciboorden();
    end if;
    return resp;	
END;
$function$
