CREATE OR REPLACE FUNCTION public.generar_orden_consumoafiliado_cargaritem(parametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
*
*/
DECLARE
--       respuestajson VARCHAR;
--       jsonafiliado jsonb;
--      jsonconsumo jsonb;
       jsonitemaud jsonb;
       vparametro jsonb;

--CURSOR
       cpracticas refcursor;
--RECORD
       rparam RECORD;
--	   rpersona RECORD;
--       rrecibocompleto RECORD;
--       rasociacion RECORD;
--       rprestador RECORD;
       rverifica RECORD;
       rpractica RECORD;
       rcodigopractica RECORD;
	   elem RECORD;
--	   ritems RECORD;
       --elem RECORD;
       rseconsume RECORD;
--       rrecibo RECORD;
       --ritems RECORD;	
--       rhayitems RECORD;
--VARIABLES
       vidplancoberturas INTEGER;
	   vpeoidtipoordenemite INTEGER;
	   vidcantidad INTEGER;
       vidtempitem integer;
       vcantidadaprobada integer;
	   vprestador BIGINT;
	   --vidcantidad INTEGER;
       --vparametro varchar;
--       vnrodocumento VARCHAR; 
--       vidtipodocumento VARCHAR; 
       venctacte BOOLEAN;
--       practicanoexiste BOOLEAN;
       vidasocconv BIGINT;
	   
begin

EXECUTE sys_dar_filtros($1) INTO rparam;

vidtempitem = 0;
venctacte = false;
	IF NOT  iftableexists('esposibleelconsumo') THEN
		CREATE TEMP TABLE esposibleelconsumo (idpractica character varying,       idplancobertura character varying,        idnomenclador character varying,        auditoria boolean,        cobertura integer,      idcapitulo character varying,         idsubcapitulo character varying,         idplancoberturas bigint,        ppccantpractica integer,      ppcperiodo character varying,         ppccantperiodos integer,         ppclongperiodo integer,         ppcprioridad integer,         idconfiguracion bigint,        serepite boolean,      ppcperiodoinicial integer,        ppcperiodofinal integer,        rcantidadconsumida integer,        rcantidadrestante integer,        nivel integer,        fechadesde date,        fechahasta date
	,      pimportepractica double precision,        pimporteamuc double precision,        pimporteafiliado double precision,        pimportesosunc double precision,        coberturaamuc double precision,      nrocuentac character varying,        idesposibleelconsumo integer,    coberturasosunc double precision,    esreintegro boolean);       
	ELSE
		DELETE FROM esposibleelconsumo;
	END IF;
--Si no existe la crea, pero si existe, puede ser que llame muchas veces para verificar el consumo de cada practica
--Recordar limpiar cuando se cambie de orden
	IF NOT  iftableexists('tempitems') THEN
		CREATE TEMP TABLE tempitems(idtemitems integer, tierror text,cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,porcentajesugerido integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4, auditoria boolean DEFAULT false, iiimporteunitario DOUBLE PRECISION, iicoberturaamuc DOUBLE PRECISION, iicoberturasosuncexpendida DOUBLE PRECISION,iiimportesosuncunitario DOUBLE PRECISION,iiimporteamucunitario DOUBLE PRECISION,iiimporteafiliadounitario DOUBLE PRECISION, idconfiguracion bigint,iiobservacion varchar
			) WITHOUT OIDS;
	ELSE
		IF rparam.limpiaritems THEN 
			DELETE FROM tempitems;
		END IF;
	END IF;

	IF NOT  iftableexists('tempitemsaprobar') THEN
		CREATE TEMP TABLE tempitemsaprobar(idtemitems integer, tierror text,cantidadsolicitada int4,cantidadaprobada int4,importeunitario float,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,idasocconv bigint,auditada boolean,porcentaje integer,porcentajesugerido integer,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4,idplancoberturas INTEGER,coberturaamuc DOUBLE PRECISION, idconfiguracion bigint) WITHOUT OIDS;
	ELSE
		DELETE FROM tempitemsaprobar;
	END IF;
       RAISE NOTICE 'rparam (%)',rparam;
      SELECT INTO rcodigopractica split_part(rparam.codigopractica,'.',1) as idnomenclador,split_part(rparam.codigopractica,'.',2) as idcapitulo,split_part(rparam.codigopractica,'.',3) as idsubcapitulo,split_part(rparam.codigopractica,'.',4) as idpractica;
	  RAISE NOTICE 'rcodigopractica (%)',rcodigopractica;
		SELECT INTO vidtempitem sum(idtemitems) as idtemitems FROM tempitems;
		vidtempitem = CASE WHEN nullvalue(vidtempitem) THEN 1 ELSE vidtempitem END;
		vidcantidad = CASE WHEN nullvalue(rparam.cantidad) THEN 1 ELSE rparam.cantidad END;
		vidasocconv  = rparam.idasocconv::bigint;
		vidplancoberturas = rparam.idplancoberturas::integer;
		INSERT INTO tempitemsaprobar(idtemitems,cantidadsolicitada,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idasocconv,idplancoberturas) 
			VALUES(vidtempitem,vidcantidad,rcodigopractica.idnomenclador,rcodigopractica.idcapitulo,rcodigopractica.idsubcapitulo,rcodigopractica.idpractica,vidasocconv,vidplancoberturas);
	-- Verifico que las practicas existen en la obra social y esten en el convenio
	OPEN cpracticas FOR select * from tempitemsaprobar;
	FETCH cpracticas INTO rpractica;
	WHILE  found LOOP
		RAISE NOTICE 'rpractica (%)',rpractica;
                RAISE NOTICE 'rparam (%)',rparam;
	        --Verifico que las practicas existen en la obra social
				SELECT INTO rverifica * FROM practicavalores 
                WHERE not internacion 
                AND idasocconv = rpractica.idasocconv
                     AND concat(idsubespecialidad,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) = concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica); 
		IF NOT FOUND THEN 
			RAISE EXCEPTION 'R-005, La practica no tiene un valor convenido.Codigo: % (CodigoConvenio,%)',concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica),concat(rpractica.idnomenclador,'.',rpractica.idcapitulo,'.',rpractica.idsubcapitulo,'.',rpractica.idpractica);
		END IF;
        	SELECT INTO rverifica * FROM plancobpersona 
						where idplancoberturas = vidplancoberturas
						AND  (nullvalue(pcpfechafin) OR pcpfechafin > current_date) 
						AND nrodoc = rparam.nrodoc 
						ORDER BY idplancoberturas LIMIT 1;
			IF NOT FOUND THEN 
				RAISE EXCEPTION 'R-006, El afiliado no tiene la cobertura solicitada.(IdPlan,%,nrodoc,%)',vidplancoberturas,rparam.nrodoc;
			END IF;
			
			SELECT INTO rverifica *   
					FROM plancobertura 	   
					NATURAL JOIN practicaplan    
					NATURAL JOIN plancobpersona  
					WHERE (idnomenclador = rpractica.idnomenclador) 
						AND (idcapitulo = rpractica.idcapitulo or idcapitulo = '**') 
						AND (idsubcapitulo = rpractica.idsubcapitulo or idsubcapitulo = '**') 
						AND (idpractica = rpractica.idpractica or idpractica = '**') 
						AND nrodoc = rparam.nrodoc 
						AND idplancoberturas = vidplancoberturas
					order by descripcion;
			IF NOT FOUND THEN 
				RAISE EXCEPTION 'R-007, El afiliado no tiene la cobertura solicitada o el plan no tienen la configuracion para la practica.(IdPlan,%,nrodoc,%,rpractica,%)',vidplancoberturas,rparam.nrodoc,rpractica;
			END IF;
			DELETE FROM esposibleelconsumo;
		   	PERFORM expendio_verificar_consumo(rpractica.idnomenclador,rpractica.idcapitulo,rpractica.idsubcapitulo,rpractica.idpractica
                 ,vidplancoberturas,  rparam.nrodoc,1,vidasocconv);
			SELECT INTO rseconsume * FROM esposibleelconsumo   as e 
					WHERE e.rcantidadrestante >= 1  AND e.fechadesde <= current_date   
					AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad LIMIT 1;

             IF FOUND THEN 
		      vcantidadaprobada = CASE WHEN rseconsume.rcantidadrestante >= rpractica.cantidadsolicitada THEN rpractica.cantidadsolicitada ELSE rseconsume.rcantidadrestante END;
		      UPDATE tempitemsaprobar SET cantidadaprobada = vcantidadaprobada
							,importeunitario = rseconsume.pimportepractica            
							,auditada = rseconsume.auditoria
							,idplancob = rseconsume.idplancobertura
							,porcentaje = rseconsume.cobertura
                            ,porcentajesugerido = rseconsume.cobertura
							,amuc = rseconsume.pimporteamuc
							,afiliado  = rseconsume.pimporteafiliado
							,sosunc  = rseconsume.pimportesosunc
                            ,coberturaamuc = rseconsume.coberturaamuc
                             ,idconfiguracion = rseconsume.idconfiguracion
			WHERE idtemitems = rpractica.idtemitems;
		  	ELSE
                      UPDATE tempitemsaprobar SET cantidadaprobada = 0
							,importeunitario = 0
							,auditada = true
							,idplancob = vidplancoberturas
							,porcentaje = 0
                            ,porcentajesugerido = case when nullvalue(rseconsume.cobertura) then 0 else rseconsume.cobertura end
							,amuc = 0
							,afiliado  = 0
							,sosunc  = 0
                            ,coberturaamuc  = 0
						WHERE idtemitems = rpractica.idtemitems;
           END IF;
	   	fetch cpracticas into rpractica;
	END LOOP;
	CLOSE cpracticas;

     vidtempitem = 0;
		OPEN cpracticas FOR SELECT * FROM tempitemsaprobar;
		FETCH cpracticas INTO elem;
		WHILE  found LOOP
 			vparametro = concat('{','"cantidadpracticas":', 1,',','"idcapitulo":', '"',elem.idcapitulo ,'"',',','"idnomenclador":','"', elem.idnomenclador ,'"',','  ,'"idsubcapitulo":','"', elem.idsubcapitulo ,'"',',','"idpractica":','"', elem.idpractica ,'"',',','"idtempitem":',vidtempitem,',"idasocconv":', elem.idasocconv,',','"idplancoberturas":', elem.idplancoberturas
			,',','"auditoria":', '"valorauditoria"',',','"tipodoc":',1,',','"porcentajesugerido":', elem.porcentajesugerido, '}');

     
      		RAISE NOTICE 'desagrupar (vparametro,%)',vparametro;
  			FOR vcontador IN 1..elem.cantidadsolicitada LOOP
    		--    RAISE NOTICE '(vcontador,%)(elem.cantidadsolicitada,%)(elem.cantidadaprobada,%)',vcontador,elem.cantidadsolicitada,elem.cantidadaprobada;
        	vidtempitem = vidtempitem + 1;
				IF vcontador <= elem.cantidadaprobada AND not elem.auditada THEN
		 		   INSERT INTO tempitems (idtemitems,cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,porcentajesugerido,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc,tierror,iiimporteunitario, iicoberturaamuc, iicoberturasosuncexpendida) 
					VALUES(vidtempitem,1,elem.importeunitario,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elem.idplancob,elem.auditada,elem.porcentaje,elem.porcentajesugerido,'','',''	,elem.amuc*1,elem.afiliado*1,elem.sosunc*1,'',elem.importeunitario,elem.coberturaamuc,(elem.porcentaje/100));
       			ELSE
	   				vparametro = CASE WHEN elem.cantidadaprobada = 0 THEN replace(vparametro::text,'valorauditoria','cantidad') ELSE 
									replace(vparametro::text,'valorauditoria','auditoria') END;  
           			--RAISE NOTICE 'else (vparametro,%)',vparametro;
           			--vparametro = replace(vparametro::text,'valor_vidtempitem',vidtempitem);
           			--RAISE NOTICE 'else (vparametro,%)',vparametro;
                    SELECT INTO jsonitemaud * FROM w_emitirconsumoafiliado_auditoria(vparametro::jsonb);
				END IF;

		   		IF existecolumtemp('tempitems', 'idconfiguracion') THEN 
               		UPDATE tempitems SET idconfiguracion = elem.idconfiguracion WHERE idtemitems = vidtempitem;
           		END IF;
	   		END LOOP;

		FETCH cpracticas INTO elem;
		END LOOP;
		CLOSE cpracticas;
 	--MaLaPi por el momento no se que mandar
    return 'true';

end;
$function$
