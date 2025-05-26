CREATE OR REPLACE FUNCTION public.expendio_modificarimporteorden(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--CURSORES
cursoritem refcursor;

--RECORD    
ritem RECORD;
rseconsume RECORD; 
rimporte  RECORD; 

--VARIABLES 
resp boolean;
laorden BIGINT; 
elcentro INTEGER;
vformapagoorden  INTEGER;
BEGIN

IF iftableexists('temp_alta_modifica_ficha_medica ') THEN
     RAISE EXCEPTION 'R-001, No existen datos para realizar el calculo del valor de la orden. ';
    
ELSE 
  IF NOT  iftableexists('esposibleelconsumo') THEN
	CREATE TEMP TABLE esposibleelconsumo (idpractica character varying,       idplancobertura character varying,        idnomenclador character varying,        auditoria boolean,        cobertura integer,      idcapitulo character varying,         idsubcapitulo character varying,         idplancoberturas bigint,        ppccantpractica integer,      ppcperiodo character varying,         ppccantperiodos integer,         ppclongperiodo integer,         ppcprioridad integer,         idconfiguracion bigint,        serepite boolean,      ppcperiodoinicial integer,        ppcperiodofinal integer,        rcantidadconsumida integer,        rcantidadrestante integer,        nivel integer,        fechadesde date,        fechahasta date
,      pimportepractica double precision,        pimporteamuc double precision,        pimporteafiliado double precision,        pimportesosunc double precision,        coberturaamuc double precision,      nrocuentac character varying,        idesposibleelconsumo integer,    coberturasosunc double precision,    esreintegro boolean);       
  ELSE
	DELETE FROM esposibleelconsumo;
  END IF;
  IF NOT  iftableexists('tempitems') THEN
	CREATE TEMP TABLE tempitems(amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4) WITHOUT OIDS;
  ELSE
	DELETE FROM tempitems;
  END IF;

--SOLO tomo los items que fueron auditados y aprobados o no requirieron auditoria
  OPEN cursoritem FOR SELECT * from temp_alta_modifica_ficha_medica NATURAL JOIN orden NATURAL JOIN  item  JOIN iteminformacion using(centro,	iditem)
NATURAL JOIN (SELECT DISTINCT idasocconv,idconvenio,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline ) as asocconvenio 
 JOIN w_usuariowebprestador USING(idconvenio) WHERE idusuarioweb<>1062 and idusuarioweb<>2942  and (iditemestadotipo=2 or iditemestadotipo=4) ;

  FETCH cursoritem INTO ritem;
  WHILE  found LOOP
   laorden = ritem.nroorden;
   elcentro = ritem.centro; 
   vformapagoorden = ritem.uwpformapagotipodefecto;

   PERFORM expendio_verificar_consumo(ritem.idnomenclador,ritem.idcapitulo,ritem.idsubcapitulo,ritem.idpractica
                 ,ritem.idplancoberturas,ritem.nrodoc,ritem.tipodoc,ritem.idasocconv);
   SELECT INTO rseconsume * FROM esposibleelconsumo   as e 
					WHERE e.rcantidadrestante >= 1  AND e.fechadesde <= current_date   
					AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad LIMIT 1;

   IF FOUND THEN      
         INSERT INTO tempitems (amuc,afiliado,sosunc) VALUES(rseconsume.pimporteamuc,rseconsume.pimporteafiliado,rseconsume.pimportesosunc);

--updateo la cobertura dado el nuevo plan 
        UPDATE item SET cobertura= ritem.cobertura  WHERE  iditem =ritem.iditem AND centro= ritem.centro;
        UPDATE iteminformacion SET iicoberturaamuc = (rseconsume.coberturaamuc ::double precision),
                                   iicoberturasosuncexpendida = (rseconsume.cobertura::double precision/100),
                                   iicoberturasosuncsugerida= (rseconsume.cobertura::double precision/100),
                                   iiimportesosuncunitario = round(rseconsume.pimportepractica::numeric,2), 
                                   iiimporteamucunitario = round(rseconsume.pimporteamuc::numeric,2), 
                                   iiimporteafiliadounitario = round(rseconsume.pimporteafiliado::numeric,2), 
                                   iierror= concat(iierror, ' ',ritem.iierror) 
       WHERE  iditem= ritem.iditem AND centro= ritem.centro;
       			                   
  ELSE
     	RAISE EXCEPTION 'R-002, Ha excedido la cantidad de practicas permitidas para el plan .(Practicas,%)',concat(ritem.idnomenclador,'.',ritem.idcapitulo,'.',ritem.idsubcapitulo,'.',ritem.idpractica,'/',ritem.idplancoberturas,'/',ritem.nrodoc,'_',ritem.tipodoc);
  END IF;

 
  FETCH cursoritem INTO ritem;
  END LOOP;
  CLOSE cursoritem;

 if not nullvalue(laorden)  then
--elimino todo lo que esta en importesorden y en importerecibo y recalculo
  DELETE FROM importesorden WHERE  nroorden = laorden AND centro = elcentro;
  DELETE FROM importesrecibo WHERE  (idrecibo, centro) IN
                ( SELECT idrecibo, centro FROM ordenrecibo WHERE  nroorden = laorden AND centro = elcentro);
  
 SELECT INTO rimporte SUM(amuc)as amuc,SUM(afiliado) as afiliado,SUM(sosunc) as sosunc  FROM  tempitems ; 
     
   INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe) VALUES (laorden,elcentro,vformapagoorden,round(CAST(rimporte.afiliado AS numeric),2) );
   INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe) VALUES (laorden,elcentro,1,round(CAST(rimporte.amuc AS numeric),2) );
   INSERT INTO importesorden(nroorden,centro,idformapagotipos,importe) VALUES (laorden,elcentro,6,round(CAST(rimporte.sosunc AS numeric),2) );

   INSERT INTO importesrecibo ( idrecibo , centro  , idformapagotipos,importe)
                (SELECT idrecibo ,centro ,  idformapagotipos , SUM(importe)
                 FROM importesorden NATURAL JOIN ordenrecibo WHERE  nroorden = laorden AND centro = elcentro
                 GROUP BY idformapagotipos, idrecibo,centro ,  idformapagotipos);
end if;

END IF;

return 'todo ok';

END;$function$
