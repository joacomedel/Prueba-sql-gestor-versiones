CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_verificar_auditoria(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*

{"NroAfiliado":"28272137","Barra":30,"uwnombre":"usudesa",NroDocumento":null,"TipoDocumento":null,"Track":null,
 "centro": 1, "idrecibo": 748447, "nroorden": 1014722, "ctdescripcion": "Orden online"
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
--RECORD 
  rseconsume RECORD;
  clasordenes refcursor;
  rlasordenes RECORD;
  rverifica RECORD;
  rrecibocompleto RECORD;
  rprestador RECORD;

--JSONB
  respuestajson jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       jsonitemaud jsonb;

BEGIN
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
	CREATE TEMP TABLE tempitems(idtemitems integer, tierror text,cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,porcentajesugerido integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4, auditoria boolean DEFAULT false,iiimporteunitario DOUBLE PRECISION, iicoberturaamuc DOUBLE PRECISION, iicoberturasosuncexpendida DOUBLE PRECISION,iiimportesosuncunitario DOUBLE PRECISION,iiimporteamucunitario DOUBLE PRECISION,iiimporteafiliadounitario DOUBLE PRECISION) WITHOUT OIDS;
ELSE
	DELETE FROM tempitems;
END IF;
      --Recordar que ellos no manda cantidad, se debe agrupar y volver a desagrupar para poder continuar
      PERFORM w_emitirconsumoafiliado_agrupar(parametro);

      SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(parametro);
      --Pongo un for pero siempre es una orden por recibo.


      -- MaLaPi 08/09/2020 Quito de las practicas posibles, las que me envian y que no estan la orden para auditar.

delete from tempitemsaprobar WHERE (idnomenclador,idcapitulo,idsubcapitulo,idpractica) NOT IN (
SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica
FROM ordenrecibo 
NATURAL JOIN orden 
NATURAL JOIN ordvalorizada 
NATURAL JOIN itemvalorizada 
NATURAL JOIN item 
NATURAL JOIN iteminformacion 
where idrecibo = parametro->>'idrecibo' AND centro=parametro->>'centro'
);

      OPEN clasordenes FOR  SELECT * FROM ordenrecibo NATURAL JOIN orden WHERE idrecibo = parametro->>'idrecibo' AND centro=parametro->>'centro';
      FETCH clasordenes  INTO rlasordenes;
      WHILE found LOOP

	--Tiene que cambier el orden para que este aprobada o rechazada
	--PERFORM expendio_cambiarestadoorden (T.nroorden, T.centro, 1) FROM (SELECT nroorden, centro, 1 FROM ttordenesgeneradas) AS T;
	--Aqui se llama sl SP que tiene que determinar si se van a aprobar o no las practicas medicas, En la tabla iteminformacion para las practicas enviadas tiene que estar la respueta. Recordar que la cantidad en este punto puede ser mayor a 1

         --MaLaPi 28-10-2019 Busco la información de auditoria
UPDATE tempitemsaprobar 
       SET auditada = (t.iditemestadotipo = 4), 
           idplancob = idplancoberturas,
           importeunitario = t.importe,
           cantidadaprobada= cantidadsolicitada,
           tierror = t.iierror, 
           porcentaje = CASE WHEN t.iditemestadotipo = 1   THEN t.iicoberturasosuncexpendida ELSE t.iicoberturasosuncauditada END,
           porcentajesugerido = t.iicoberturasosuncsugerida*100,
           coberturaamuc = CASE WHEN (t.iicoberturaamuc IS NULL) THEN 0 ELSE t.iicoberturaamuc END ---Belen y VAS 07052025
FROM (
SELECT iteminformacion.*,item.* 
FROM ordenrecibo 
NATURAL JOIN orden 
NATURAL JOIN ordvalorizada 
NATURAL JOIN itemvalorizada 
NATURAL JOIN item 
NATURAL JOIN iteminformacion 
WHERE  idrecibo = parametro->>'idrecibo' AND centro=parametro->>'centro'
) as t
WHERE t.idnomenclador = tempitemsaprobar.idnomenclador AND t.idcapitulo = tempitemsaprobar.idcapitulo AND t.idsubcapitulo = tempitemsaprobar.idsubcapitulo AND t.idpractica = tempitemsaprobar.idpractica;


--MaLaPi 13-06-2019 Genera el desaagrupamiento de las practicas para poder emitir la orden, se carga la tabla tempitems
	PERFORM w_emitirconsumoafiliado_desagrupar(parametro);
        SELECT INTO rprestador * from prestador WHERE replace(pcuit,'-','') ilike parametro->>'CuilEfector';
	INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,sosunc,enctacte,idprestador,ordenreemitida,centroreemitida,nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro,autogestion) 
	(
		SELECT jsonafiliado->>'nrodocumento',1,rlasordenes.nroorden,null,rlasordenes.centro,56,sum(amuc),sum(afiliado),sum(sosunc),false,rprestador.idprestador,null,null,null,1,rlasordenes.idasocconv,null,null,null,true
		FROM tempitems 
	);

	SELECT INTO rrecibocompleto idrecibo,centro FROM recibo WHERE idrecibo = rlasordenes.idrecibo AND centro = rlasordenes.centro; 
	respuestajson = row_to_json(rrecibocompleto);
	SELECT INTO respuestajson w_ordenrecibo_informacion_json(respuestajson);

      FETCH clasordenes  INTO rlasordenes;
      END LOOP;
      CLOSE clasordenes; 

     
		
      return respuestajson;

END;

$function$
