CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_desagrupar_debug(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
       respuestajson jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       jsonitemaud jsonb;

--CURSOR
       cpracticas refcursor;
--RECORD
       rpersona RECORD;
       rpractica RECORD;
       elem RECORD;
       ritems RECORD;	

--VARIABLES
       vidtempitem integer;
       vparametro VARCHAR; 
       vcontador INTEGER;	
	
BEGIN 

vidtempitem = 0;
OPEN cpracticas FOR SELECT * FROM tempitemsaprobar;
FETCH cpracticas INTO elem;
WHILE  found LOOP
 

     vparametro = concat('{','"cantidadpracticas":', 1,',','"idcapitulo":', '"',elem.idcapitulo ,'"',',','"idnomenclador":','"', elem.idnomenclador ,'"',','  ,'"idsubcapitulo":','"', elem.idsubcapitulo ,'"',',','"idpractica":','"', elem.idpractica ,'"',',','"idtempitem":', vidtempitem,',','"idasocconv":', elem.idasocconv,',','"idplancoberturas":', elem.idplancoberturas
,',','"auditoria":', '"valorauditoria"',',','"cantidadrestante":','"valoracantidadrestante"',',','"nrodoc":',parametro->>'NroAfiliado',',','"tipodoc":',1, '}');
     
      RAISE NOTICE '(parametro,%)',parametro;
  --  RAISE NOTICE '(elem.auditada,%)(elem.cantidadsolicitada,%)(elem.cantidadaprobada,%)',elem.auditada,elem.cantidadsolicitada,elem.cantidadaprobada;
   FOR vcontador IN 1..elem.cantidadsolicitada LOOP
    --    RAISE NOTICE '(vcontador,%)(elem.cantidadsolicitada,%)(elem.cantidadaprobada,%)',vcontador,elem.cantidadsolicitada,elem.cantidadaprobada;
        vidtempitem = vidtempitem + 1;
	IF vcontador <= elem.cantidadaprobada AND not elem.auditada THEN
		
	   INSERT INTO tempitems (idtemitems,cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc,tierror,iiimporteunitario, iicoberturaamuc, iicoberturasosuncexpendida,iiimportesosuncunitario,iiimporteamucunitario,iiimporteafiliadounitario) 
		VALUES(vidtempitem,1,elem.importeunitario,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elem.idplancob,elem.auditada,elem.porcentaje,'','',''	,elem.amuc*1,elem.afiliado*1,elem.sosunc*1,'',elem.importeunitario,elem.coberturaamuc,(elem.porcentaje/100),elem.sosunc,elem.amuc,elem.afiliado);
	ELSE
	 --  vparametro = CASE WHEN elem.cantidadaprobada = 0 THEN replace(vparametro,'valorauditoria','cantidad') ELSE 
	--		replace(vparametro,'valorauditoria','auditoria') END;  
         --   RAISE NOTICE '(vparametro,%)',vparametro;
         -- KR 05-08-19  SELECT INTO jsonitemaud * FROM w_emitirconsumoafiliado_auditoria(vparametro::jsonb);
            INSERT INTO tempitems (idtemitems,cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc,iiimporteunitario, iicoberturaamuc, iicoberturasosuncexpendida,tierror,auditoria,iiimportesosuncunitario,iiimporteamucunitario,iiimporteafiliadounitario) 
		VALUES(vidtempitem,1,elem.importeunitario,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elem.idplancob,elem.auditada,elem.porcentaje,'','',''	,elem.amuc*1,elem.afiliado*1,elem.sosunc*1,elem.importeunitario,elem.coberturaamuc,(elem.porcentaje/100), CASE WHEN elem.cantidadaprobada = 0 THEN 'No quedan practicas para ser consumidas. Requiere autorizacion.' ELSE 'La practica requiere autorizacion.' END, true,elem.sosunc,elem.amuc,elem.afiliado );
	END IF;
 

   END LOOP;


FETCH cpracticas INTO elem;
END LOOP;
CLOSE cpracticas;


 return respuestajson;

end;
$function$
