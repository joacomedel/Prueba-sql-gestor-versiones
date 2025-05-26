CREATE OR REPLACE FUNCTION public.w_consultarconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"NroAfiliado":"28272137","Barra":30,"NroDocumento":null,"TipoDocumento":null,"Track":null
,"ApellidoEfector":"GUIDO","NombreEfector":"PIANTONI FEDERICO","CuilEfector":"20235079241","Diagnostico":null,"FechaConsumo":null,"MatriculaEfector":"2375"
,"CategoriaEfector":"B",
,"ConsumosWeb":[{"Cantidad":2,"CodigoConvenio":"12.46.01.13","DescripcionCodigoConvenio":"Topografía corneal computada bilateral"}
		,{"Cantidad":2,"CodigoConvenio":"12.46.01.12","DescripcionCodigoConvenio":"Paquimetría bilateral"}
		,{"Cantidad":1,"CodigoConvenio":"12.46.01.28","DescripcionCodigoConvenio":"Curva diaria de presión ocular"}
		,{"Cantidad":1,"CodigoConvenio":"12.46.01.19","DescripcionCodigoConvenio":"Tomografia optica de coherencia (por ojo)"}
		] }
*/
DECLARE
       respuestajson jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       cpracticas refcursor;
       rpersona RECORD;
       rrecibocompleto RECORD;
       rasociacion RECORD;
       rprestador RECORD;
       rverifica RECORD;
       rpractica RECORD;
       elem RECORD;
       rseconsume RECORD;
       rrecibo RECORD;	
       vidplancoberturas INTEGER;
	
begin
-- MaLaPi 01-11-2018 Siempre se usa el plan General
vidplancoberturas = 1; 
IF NOT  iftableexists('temporden') THEN
	CREATE TEMP TABLE temporden(nrodoc varchar(8), 	tipodoc int  NOT NULL,  	numorden bigint ,  	ctroorden integer, 	centro int4 NOT NULL, 	recibo boolean,  	tipo int8,         amuc float ,  	afiliado float ,  	sosunc float,         enctacte boolean, 	idprestador INTEGER, 	ordenreemitida INTEGER, 	centroreemitida INTEGER,	nromatricula INTEGER,  	cantordenes INTEGER,   	idasocconv BIGINT,  	nroreintegro BIGINT,  	anio INTEGER,         autogestion BOOLEAN,  	idcentroreintegro INTEGER,     formapago INTEGER 	) WITHOUT OIDS;
ELSE 
	DELETE FROM temporden;
END IF;
IF NOT  iftableexists('esposibleelconsumo') THEN
	CREATE TEMP TABLE esposibleelconsumo (idpractica character varying,       idplancobertura character varying,        idnomenclador character varying,        auditoria boolean,        cobertura integer,      idcapitulo character varying,         idsubcapitulo character varying,         idplancoberturas bigint,        ppccantpractica integer,      ppcperiodo character varying,         ppccantperiodos integer,         ppclongperiodo integer,         ppcprioridad integer,         idconfiguracion bigint,        serepite boolean,      ppcperiodoinicial integer,        ppcperiodofinal integer,        rcantidadconsumida integer,        rcantidadrestante integer,        nivel integer,        fechadesde date,        fechahasta date
,      pimportepractica double precision,        pimporteamuc double precision,        pimporteafiliado double precision,        pimportesosunc double precision,        coberturaamuc double precision,      nrocuentac character varying,        idesposibleelconsumo integer,    coberturasosunc double precision,    esreintegro boolean);       
ELSE
	DELETE FROM esposibleelconsumo;
END IF;

IF NOT  iftableexists('tempitems') THEN
	CREATE TEMP TABLE tempitems(cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4) WITHOUT OIDS;
ELSE
	DELETE FROM tempitems;
END IF;


SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(parametro);

       --Verifico que el convenio sea valido o este vigente.
	select INTO rasociacion * from asocconvenio natural join convenio natural join w_usuariowebprestador NATURAL JOIN w_usuarioweb
		WHERE uwnombre = parametro->>'uwnombre' AND acfechafin >= current_date;
	IF NOT FOUND THEN 
		RAISE EXCEPTION 'R-002, Convenio inexistente o vencido.(IdConvenio,%)',parametro->>'uwnombre';
	END IF;
	--Verifico que el prestador este dado de alta
	select INTO rprestador * from prestador WHERE replace(pcuit,'-','') ilike parametro->>'CuilEfector';
	IF NOT FOUND THEN 
		RAISE EXCEPTION 'R-003, Prestador Efector no esta registrado.(CuilEfector,%)',parametro->>'CuilEfector';
	END IF;
	     --SELECT INTO jsonconsumo parametro->'ConsumosWeb';
             -- select into elem * from jsonb_to_recordset(parametro->'ConsumosWeb') as x("Cantidad" int, "CodigoConvenio" text,"DescripcionCodigoConvenio" text,"IdPlan" int) limit 1;
	     --RAISE NOTICE 'Parametros (%)',elem;
	-- Verifico que las practicas existen en la obra social y esten en el convenio
	OPEN cpracticas FOR select * from jsonb_to_recordset(parametro->'ConsumosWeb') as x("Cantidad" int, "CodigoConvenio" text,"DescripcionCodigoConvenio" text,"IdPlan" int);
	FETCH cpracticas INTO elem;
	WHILE  found LOOP
                RAISE NOTICE 'elem (%)',elem;
		SELECT INTO rpractica split_part(elem."CodigoConvenio",'.',1) as idnomenclador,split_part(elem."CodigoConvenio",'.',2) as idcapitulo,split_part(elem."CodigoConvenio",'.',3) as idsubcapitulo,split_part(elem."CodigoConvenio",'.',4) as idpractica;
		RAISE NOTICE 'rpractica (%)',rpractica;
	        --Verifico que las practicas existen en la obra social
		SELECT INTO rverifica * FROM practica WHERE concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = elem."CodigoConvenio";
		IF NOT FOUND THEN 
			RAISE EXCEPTION 'R-004, Codigo de la practica invalido.(CodigoConvenio,%)',elem."CodigoConvenio";
		END IF;
		--Verifico que las practicas esta en el convenio
		SELECT INTO rverifica * FROM practconvval  
			JOIN asocconvenio ON practconvval.idasocconv = asocconvenio.idasocconv
			WHERE idconvenio = rasociacion.idconvenio AND acfechafin >= current_date 
				AND tvvigente AND concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = elem."CodigoConvenio"
		LIMIT 1;
		IF NOT FOUND THEN 
			RAISE EXCEPTION 'R-005, La practica no tiene un valor convenido.(CodigoConvenio,%)',elem."CodigoConvenio";
		ELSE 
			rasociacion.idasocconv = rverifica.idasocconv;
		END IF;
		--tipo de la orden 56 
		--Verifico que el afiliado tenga ese plan de cobertura
			SELECT INTO rverifica * FROM plancobpersona where idplancoberturas = vidplancoberturas AND  nullvalue(pcpfechafin) AND nrodoc = jsonafiliado->>'nrodocumento';
			IF NOT FOUND THEN 
				RAISE EXCEPTION 'R-006, El afiliado no tiene la cobertura solicitada.(IdPlan,%)',vidplancoberturas;
			END IF;
			SELECT INTO rverifica *   
					FROM plancobertura 	   
					NATURAL JOIN practicaplan    
					NATURAL JOIN plancobpersona  
					WHERE (idnomenclador = rpractica.idnomenclador) 
						AND (idcapitulo = rpractica.idcapitulo or idcapitulo = '**') 
						AND (idsubcapitulo = rpractica.idsubcapitulo or idsubcapitulo = '**') 
						AND (idpractica = rpractica.idpractica or idpractica = '**') 
						AND nrodoc = jsonafiliado->>'nrodocumento'
						AND idplancoberturas = vidplancoberturas
					order by descripcion;
			IF NOT FOUND THEN 
				RAISE EXCEPTION 'R-007, El afiliado o el plan no tienen la configuracion para la practica.(IdPlan,%)',vidplancoberturas;
			END IF;
		
		DELETE FROM esposibleelconsumo;
		PERFORM expendio_verificar_consumo(rpractica.idnomenclador,rpractica.idcapitulo,rpractica.idsubcapitulo,rpractica.idpractica
                 ,vidplancoberturas,  jsonafiliado->>'nrodocumento',1,rasociacion.idasocconv);
		SELECT INTO rseconsume * FROM esposibleelconsumo   as e 
					WHERE e.rcantidadrestante >= elem."Cantidad"  AND e.fechadesde <= current_date   
					AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad;
		IF FOUND THEN 
			INSERT INTO tempitems (cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc) 
			VALUES(elem."Cantidad",rseconsume.pimportepractica,rpractica.idnomenclador,rpractica.idcapitulo,rpractica.idsubcapitulo,rpractica.idpractica,rseconsume.idplancobertura,null,rseconsume.cobertura,'','',''
				,rseconsume.pimporteamuc*elem."Cantidad",rseconsume.pimporteafiliado*elem."Cantidad",rseconsume.pimportesosunc*elem."Cantidad");
			
		ELSE
			RAISE NOTICE 'R-008, No quedan practicas para ser consumidas.(IdPlan,%)',vidplancoberturas;
		END IF;

       	fetch cpracticas into elem;
	END LOOP;
	CLOSE cpracticas;
		INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,sosunc,enctacte,idprestador,ordenreemitida,centroreemitida,nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro,autogestion) 
		(
		SELECT jsonafiliado->>'nrodocumento',1,null,null,centro(),56,sum(amuc),sum(afiliado),sum(sosunc),false,null,null,null,null,elem."Cantidad",rasociacion.idasocconv,null,null,null,true
		FROM tempitems 
		);
	  
	 SELECT INTO rrecibo * FROM expendio_orden();
	IF FOUND THEN
		DELETE FROM ttordenesgeneradas;
		SELECT INTO rrecibocompleto * FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = centro(); 
		respuestajson = row_to_json(rrecibocompleto);
		RAISE NOTICE 'Recibo Orden Emitidas.(rrecibo,%)',rrecibo;
	 END IF;

      return respuestajson;

end;
$function$
