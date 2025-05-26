CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_debug(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroAfiliado":"28272137","Barra":30,"uwnombre":"usudesa",NroDocumento":null,"TipoDocumento":null,"Track":null
,"ApellidoEfector":"GUIDO","NombreEfector":"PIANTONI FEDERICO","CuilEfector":"20235079241","Diagnostico":null,"FechaConsumo":null,"MatriculaEfector":"2375"
,"CategoriaEfector":"B",
,"ConsumosWeb":[{"Cantidad":2,"CodigoConvenio":"12.46.01.13","DescripcionCodigoConvenio":"Topografía corneal computada bilateral"}
		,{"Cantidad":2,"CodigoConvenio":"12.46.01.12","DescripcionCodigoConvenio":"Paquimetría bilateral"}
		,{"Cantidad":1,"CodigoConvenio":"12.46.01.28","DescripcionCodigoConvenio":"Curva diaria de presión ocular"}
		,{"Cantidad":1,"CodigoConvenio":"12.46.01.19","DescripcionCodigoConvenio":"Tomografia optica de coherencia (por ojo)"}
		] }
* MaLaPi 14-02-2019 : Quito la cantidad, para el caso de que se requiera autorizar mas de una practica, de sebe repetir el codigo.

{"NroAfiliado":"28272137","Barra":30,"uwnombre":"usudesa",NroDocumento":null,"TipoDocumento":null,"Track":null
,"ApellidoEfector":"GUIDO","NombreEfector":"PIANTONI FEDERICO","CuilEfector":"20235079241","Diagnostico":null,"FechaConsumo":null,"MatriculaEfector":"2375"
,"CategoriaEfector":"B",
,"ConsumosWeb":[{"CodigoConvenio":"12.46.01.13","DescripcionCodigoConvenio":"Topografía corneal computada bilateral"}
		,{"CodigoConvenio":"12.46.01.13","DescripcionCodigoConvenio":"Topografía corneal computada bilateral"}
		,{"CodigoConvenio":"12.46.01.12","DescripcionCodigoConvenio":"Paquimetría bilateral"}
		,{"CodigoConvenio":"12.46.01.28","DescripcionCodigoConvenio":"Curva diaria de presión ocular"}
		,{"CodigoConvenio":"12.46.01.19","DescripcionCodigoConvenio":"Tomografia optica de coherencia (por ojo)"}
		] }

*/
DECLARE
       respuestajson jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       jsonitemaud jsonb;

--CURSOR
       cpracticas refcursor;
--RECORD
       rpersona RECORD;
       rrecibocompleto RECORD;
       rasociacion RECORD;
       rprestador RECORD;
       rverifica RECORD;
       rpractica RECORD;
       --elem RECORD;
       rseconsume RECORD;
       rrecibo RECORD;
       --ritems RECORD;	
--VARIABLES
       vidplancoberturas INTEGER;
       vidtempitem integer;
       vcantidadaprobada integer;
       --vparametro varchar;
       vnrodocumento VARCHAR; 
       vauditoria BOOLEAN;
	
begin
-- MaLaPi 01-11-2018 Siempre se usa el plan General
vidplancoberturas = 1; 
vidtempitem = 0;
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

IF NOT  iftableexists('tempitems') THEN
	CREATE TEMP TABLE tempitems(idtemitems integer, tierror text,cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4, auditoria boolean DEFAULT false, iiimporteunitario DOUBLE PRECISION, iicoberturaamuc DOUBLE PRECISION, iicoberturasosuncexpendida DOUBLE PRECISION,iiimportesosuncunitario DOUBLE PRECISION,iiimporteamucunitario DOUBLE PRECISION,iiimporteafiliadounitario DOUBLE PRECISION
        ) WITHOUT OIDS;
ELSE
	DELETE FROM tempitems;
END IF;
       --CREATE TEMP TABLE tempitemsaprobar(idtemitems integer, tierror text,cantidadsolicitada int4,cantidadaprobada int4,importeunitario float,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar
	--,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4) WITHOUT OIDS;

        --MaLaPi 13-06-2019 Genera el agrupamiento de las practicas para que se puedan verificar 
        PERFORM w_emitirconsumoafiliado_agrupar(parametro);

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
        ELSE 
             IF parametro->>'CategoriaEfector' <> rprestador.pcategoria THEN
                 UPDATE prestador SET pcategoria = CASE WHEN trim(parametro->>'CategoriaEfector') = 'D' THEN 'E' ELSE trim(parametro->>'CategoriaEfector') END WHERE idprestador = rprestador.idprestador;
             END IF;  
	END IF;
	-- Verifico que las practicas existen en la obra social y esten en el convenio
	OPEN cpracticas FOR select * from tempitemsaprobar;
	FETCH cpracticas INTO rpractica;
	WHILE  found LOOP
		RAISE NOTICE 'rpractica (%)',rpractica;
	        --Verifico que las practicas existen en la obra social
		SELECT INTO rverifica * FROM practica 
                                       WHERE concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica);
		IF NOT FOUND THEN 
			RAISE EXCEPTION 'R-004, Codigo de la practica invalido.[CodigoConvenio,%]',concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica);
		END IF;
		--Verifico que las practicas esta en el convenio
		SELECT INTO rverifica * FROM practconvval  
			JOIN asocconvenio ON practconvval.idasocconv = asocconvenio.idasocconv
			WHERE idconvenio = rasociacion.idconvenio AND acfechafin >= current_date 
				AND tvvigente AND concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica)
		LIMIT 1;
		IF NOT FOUND THEN 
			RAISE EXCEPTION 'R-005, La practica no tiene un valor convenido.(CodigoConvenio,%)',concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica);
		ELSE 
			rasociacion.idasocconv = rverifica.idasocconv;
			UPDATE  tempitemsaprobar SET idasocconv = rasociacion.idasocconv;
		END IF;
                      
		--tipo de la orden 56 
		--Verifico que el afiliado tenga ese plan de cobertura
			SELECT INTO rverifica * FROM plancobpersona 
						where idplancoberturas IN (1,12,29)  --Solo se pueden usar el General/Reciprocidad/Rec Coseguro
						AND  nullvalue(pcpfechafin) 
						AND nrodoc = jsonafiliado->>'nrodocumento' 
                                                ORDER BY idplancoberturas LIMIT 1;
			IF NOT FOUND THEN 
				RAISE EXCEPTION 'R-006, El afiliado no tiene la cobertura solicitada.(IdPlan,%)',vidplancoberturas;
			ELSE
                                vidplancoberturas = rverifica.idplancoberturas; 
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
                
	/*	vparametro = concat('{','"cantidadpracticas":', rpractica.cantidadsolicitada ,',','"idcapitulo":', '"',rpractica.idcapitulo ,'"',',','"idnomenclador":','"', rpractica.idnomenclador ,'"',','  ,'"idsubcapitulo":','"', rpractica.idsubcapitulo ,'"',',','"idpractica":','"', rpractica.idpractica ,'"',',','"idtempitem":', vidtempitem,',','"idasocconv":', rasociacion.idasocconv,',','"idplancoberturas":', vidplancoberturas
				,',','"auditoria":', '"valorauditoria"',
				',','"cantidadrestante":','"valoracantidadrestante"'
				, '}');
                        RAISE NOTICE '(vparametro,%)',vparametro;*/
  

		PERFORM expendio_verificar_consumo(rpractica.idnomenclador,rpractica.idcapitulo,rpractica.idsubcapitulo,rpractica.idpractica
                 ,vidplancoberturas,  jsonafiliado->>'nrodocumento',1,rasociacion.idasocconv);
		SELECT INTO rseconsume * FROM esposibleelconsumo   as e 
					WHERE e.rcantidadrestante >= 1  AND e.fechadesde <= current_date   
					AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad LIMIT 1;

		IF FOUND THEN 
		      vcantidadaprobada = CASE WHEN rseconsume.rcantidadrestante >= rpractica.cantidadsolicitada THEN rpractica.cantidadsolicitada ELSE rseconsume.rcantidadrestante END;
		      vauditoria = rseconsume.auditoria;
                     
		ELSE
                      vcantidadaprobada = 0;
		      vauditoria = true;			

		END IF;

                UPDATE tempitemsaprobar SET cantidadaprobada = vcantidadaprobada
							,importeunitario = rseconsume.pimportepractica
							,auditada = vauditoria
							,idplancob = rseconsume.idplancobertura
							,porcentaje = rseconsume.cobertura
							,amuc = rseconsume.pimporteamuc
							,afiliado  = rseconsume.pimporteafiliado
							,sosunc  = rseconsume.pimportesosunc
                                                        ,coberturaamuc = rseconsume.coberturaamuc
			WHERE idtemitems = rpractica.idtemitems;

       	fetch cpracticas into rpractica;
	END LOOP;
	CLOSE cpracticas;

		--MaLaPi 13-06-2019 Genera el desaagrupamiento de las practicas para poder emitir la orden, se carga la tabla tempitems
		PERFORM w_emitirconsumoafiliado_desagrupar_debug(parametro);
		INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,sosunc,enctacte,idprestador,ordenreemitida,centroreemitida,nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro,autogestion) 
		(
		SELECT jsonafiliado->>'nrodocumento',1,null,null,centro(),56,sum(amuc),sum(afiliado),sum(sosunc),false,rprestador.idprestador,null,null,null,1,rasociacion.idasocconv,null,null,null,true
		FROM tempitems 
		);
	  
	 SELECT INTO rrecibo * FROM expendio_orden();
	IF FOUND THEN
               --KR 06-05-19 Guardo el estado de la orden en la tabla cambioestadoorden 
                PERFORM expendio_cambiarestadoorden (T.nroorden, T.centro, 1) 
                            FROM (SELECT nroorden, centro, 1 FROM ttordenesgeneradas) AS T;
		
		SELECT INTO rrecibocompleto idrecibo,centro FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = centro(); 
		respuestajson = row_to_json(rrecibocompleto);
		SELECT INTO respuestajson w_ordenrecibo_informacion_json(respuestajson);
		--SELECT INTO rrecibocompleto * FROM recibo WHERE idrecibo = rrecibo.idrecibo AND centro = centro(); 
		--respuestajson = row_to_json(rrecibocompleto);
		--RAISE NOTICE 'Recibo Orden Emitidas.(rrecibo,%)',rrecibo;

                --MaLaPi 13-06-2019 Elimino aquellas ordenes que sosunc no cubre 
--KR 27-06-19 ahora se AUDITAN las las ordenes cuyos items requieren auditoria (campo auditoria en tempitems) 

                vnrodocumento = jsonafiliado->>'nrodocumento'; 
                RAISE NOTICE 'vnrodocumento (%)',vnrodocumento;
               
                PERFORM w_consumoafiliado_generaauditoria(concat('{"nroorden":',t.nroorden,',', '"centro":',t.centro,',', '"nrodoc":','"',vnrodocumento,'"',',', '"tipodoc":1','}')::jsonb) 
                FROM (
                      SELECT nroorden,centro FROM ttordenesgeneradas 
                 ) as t;

--MaLaPi 23-07-2019 Agrego para tener la informacion de categoria que envia el prestador que pide la autorizacion
INSERT INTO ordenonlineinfoextra (nroorden,centro,categoriaefector,apellidoefector,nombreefector,cuilefector,diagnostico,matriculaefector)  (
SELECT nroorden,centro,trim(parametro->>'CategoriaEfector') as categoriaefector,parametro->>'ApellidoEfector' as apellidoefector,parametro->>'NombreEfector' as nombreefector,parametro->>'CuilEfector' as cuilefector
,parametro->>'Diagnostico' as diagnostico,parametro->>'MatriculaEfector' as matriculaefector FROM (
               SELECT nroorden,centro FROM ttordenesgeneradas 
            ) as t
            );


             DELETE FROM ttordenesgeneradas;

	 END IF;

      return respuestajson;

end;$function$
