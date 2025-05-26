CREATE OR REPLACE FUNCTION public.generar_orden_consumoafiliado_config(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
*
*/
DECLARE
       respuestajson VARCHAR;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       jsonitemaud jsonb;
       vparametro jsonb;

--CURSOR
       cpracticas refcursor;
--RECORD
       rparam RECORD;
	   rpersona RECORD;
       rrecibocompleto RECORD;
       rasociacion RECORD;
       rprestador RECORD;
       rverifica RECORD;
       rpractica RECORD;
	   elem RECORD;
	   ritems RECORD;
       --elem RECORD;
       rseconsume RECORD;
       rrecibo RECORD;
       --ritems RECORD;	
       rhayitems RECORD;
--VARIABLES
       vidplancoberturas INTEGER;
	   vpeoidtipoordenemite INTEGER;
       vidtempitem integer;
       vcantidadaprobada integer;
	   vprestador BIGINT;
       --vparametro varchar;
       vnrodocumento VARCHAR; 
       vidtipodocumento VARCHAR; 
       venctacte BOOLEAN;
       practicanoexiste BOOLEAN;
       vidasocconv BIGINT;
       vidplancobertura BIGINT;
 
       vparam VARCHAR;
	   
begin

EXECUTE sys_dar_filtros($1) INTO rparam;

-- MaLaPi 01-11-2018 Siempre se usa el plan General
vidplancoberturas = 1; 
vidtempitem = 0;
venctacte = false;
IF NOT  iftableexists('temporden') THEN
	CREATE TEMP TABLE temporden(nrodoc varchar(8), 	tipodoc int  NOT NULL,  	numorden bigint ,  	ctroorden integer, 	centro int4 NOT NULL, 	recibo boolean,  	tipo int8,         amuc float ,  	afiliado float ,  	sosunc float,         enctacte boolean, 	idprestador BIGINT, 	ordenreemitida INTEGER, 	centroreemitida INTEGER,	nromatricula INTEGER,  	cantordenes INTEGER,   	idasocconv BIGINT,  	nroreintegro BIGINT,  	anio INTEGER,         autogestion BOOLEAN,  	idcentroreintegro INTEGER,     formapago INTEGER 	) WITHOUT OIDS;
ELSE 
	DELETE FROM temporden;
END IF;
IF NOT  iftableexists('esposibleelconsumo') THEN
	CREATE TEMP TABLE esposibleelconsumo (idpractica character varying,       idplancobertura character varying,        idnomenclador character varying,        auditoria boolean,        cobertura integer,      idcapitulo character varying,         idsubcapitulo character varying,         idplancoberturas bigint,        ppccantpractica integer,      ppcperiodo character varying,         ppccantperiodos integer,         ppclongperiodo integer,         ppcprioridad integer,         idconfiguracion bigint,        serepite boolean,      ppcperiodoinicial integer,        ppcperiodofinal integer,        rcantidadconsumida integer,        rcantidadrestante integer,        nivel integer,        fechadesde date,        fechahasta date
,      pimportepractica double precision,        pimporteamuc double precision,        pimporteafiliado double precision,        pimportesosunc double precision,        coberturaamuc double precision,      nrocuentac character varying,        idesposibleelconsumo integer,    coberturasosunc double precision,    esreintegro boolean);       
ELSE
	DELETE FROM esposibleelconsumo;
END IF;

IF NOT  iftableexists('ttordenesgeneradas_2') THEN

    CREATE TEMP TABLE ttordenesgeneradas_2(
           estaenitem BOOLEAN DEFAULT false,
           nroorden   bigint,
           centro     int4
           ) WITHOUT OIDS;

ELSE
	DELETE FROM ttordenesgeneradas_2;
END IF;

IF NOT  iftableexists('tempitems') THEN
	CREATE TEMP TABLE tempitems(idtemitems integer, tierror text,cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,porcentajesugerido integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4, auditoria boolean DEFAULT false, iiimporteunitario DOUBLE PRECISION, iicoberturaamuc DOUBLE PRECISION, iicoberturasosuncexpendida DOUBLE PRECISION,iiimportesosuncunitario DOUBLE PRECISION,iiimporteamucunitario DOUBLE PRECISION,iiimporteafiliadounitario DOUBLE PRECISION, idconfiguracion bigint,iiobservacion varchar
        ) WITHOUT OIDS;
ELSE
	DELETE FROM tempitems;
END IF;

IF NOT  iftableexists('tempitemsaprobar') THEN
	CREATE TEMP TABLE tempitemsaprobar(idtemitems integer, tierror text,cantidadsolicitada int4,cantidadaprobada int4,importeunitario float,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,idasocconv bigint,auditada boolean,porcentaje integer,porcentajesugerido integer,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4,idplancoberturas INTEGER,coberturaamuc DOUBLE PRECISION, idconfiguracion bigint) WITHOUT OIDS;
ELSE
	DELETE FROM tempitemsaprobar;
END IF;

	

--RAISE NOTICE 'ConsumosWeb (%)',parametro->'ConsumosWeb'; 
	OPEN cpracticas FOR SELECT *
								FROM practica_emitirorden 
								WHERE nullvalue(peofechaanulacion) 
									AND peocodigopractica = rparam.peocodigopractica;
	FETCH cpracticas INTO elem;
	WHILE  found LOOP
	vpeoidtipoordenemite = CASE WHEN elem.peoidtipoordenemite <> '**' THEN elem.peoidtipoordenemite::INTEGER ELSE 2 END; 
	--Cargo la tabla tempitems para la practica que se requiere emitir, esta verifica el consumo y determina si requiere o no auditoria
	
        vidasocconv = CASE WHEN elem.peoidasocconvemite <> '**' THEN elem.peoidasocconvemite::BIGINT ELSE rparam.idasocconv::BIGINT END;  

        vidplancobertura = CASE WHEN elem.peoidplancoberturaemite <> '**' THEN elem.peoidplancoberturaemite::BIGINT ELSE rparam.idplancoberturas::BIGINT END; 
         vparam = concat('{ idplancoberturas=',vidplancobertura,',idasocconv=',vidasocconv,',cantidad=',elem.peocantidademite,' ,nrodoc=',rparam.nrodoc,',codigopractica=',elem.peocodigopracticaemite,',limpiaritems = ',false,' }');

	PERFORM generar_orden_consumoafiliado_cargaritem(vparam);
	
	
	fetch cpracticas into elem;
	END LOOP;
	CLOSE cpracticas;
	
	RAISE NOTICE 'verifico si hay datos en items para mandar a generar la orden ';
	
		
       SELECT INTO rhayitems *  FROM tempitems;
       IF FOUND THEN --HAY datos para generar la orden
             RAISE NOTICE 'Si hay datos (%)',rhayitems;
	    vnrodocumento = rparam.nrodoc ;
        vidtipodocumento  = rparam.tipodoc;
		venctacte = false;
		vprestador = 7841; --Sello ilegible

        INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,sosunc,enctacte,idprestador,ordenreemitida,centroreemitida,nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro,autogestion) 
		(
		SELECT rparam.nrodoc,rparam.tipodoc,null,null,centro(),vpeoidtipoordenemite,sum(amuc),sum(afiliado),sum(sosunc),venctacte,vprestador,null,null,null,1,vidasocconv,null,null,null,true
		FROM tempitems 
		);
	  	 SELECT INTO rrecibo * FROM expendio_orden();
		IF FOUND THEN
               --KR 06-05-19 Guardo el estado de la orden en la tabla cambioestadoorden 
                PERFORM expendio_cambiarestadoorden (T.nroorden, T.centro, 1) 
                            FROM (SELECT nroorden, centro, 1 FROM ttordenesgeneradas) AS T;
		
		SELECT INTO rrecibocompleto idrecibo,centro FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = centro(); 

		PERFORM w_consumoafiliado_generaauditoria(concat('{"nroorden":',t.nroorden,',', '"centro":',t.centro,',', '"nrodoc":','"',vnrodocumento,'"',',', '"tipodoc":',vidtipodocumento,'}')::jsonb) 
                FROM (
                      SELECT nroorden,centro FROM ttordenesgeneradas 
                 ) as t;

             INSERT INTO ttordenesgeneradas_2(nroorden,centro) 
             ( SELECT nroorden,centro FROM ttordenesgeneradas);   
             DELETE FROM ttordenesgeneradas;

	 END IF;  
       ELSE
          RAISE EXCEPTION 'R-008, Para dicho convenio, el afiliado excedió el consumo de practicas o estas requieren auditoria. (IdConvenio,%)',parametro->>'uwnombre';
       END IF;

      return concat('{ nroorden = ',rrecibo.nroorden,',', 'centro =',rrecibo.centro,',', 'nrodoc =',vnrodocumento,',', 'tipodoc =',vidtipodocumento,'}');

end;
$function$
