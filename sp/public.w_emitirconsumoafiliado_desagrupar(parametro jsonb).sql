CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_desagrupar(parametro jsonb)
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
 
--KR 17-12-19 saque '"cantidadrestante":','"valoracantidadrestante"',',', porque da error al no ser reemplazado, no se utiliza. 
--'"nrodoc":',parametro->>'NroAfiliado'::text,',', 
     /*vparametro = concat('{','"cantidadpracticas":', 1,',','"idcapitulo":', '"',elem.idcapitulo ,'"',',','"idnomenclador":','"', elem.idnomenclador ,'"',','  ,'"idsubcapitulo":','"', elem.idsubcapitulo ,'"',',','"idpractica":','"', elem.idpractica ,'"',',','"idtempitem":', 'valor_vidtempitem',',','"idasocconv":', elem.idasocconv,',','"idplancoberturas":', elem.idplancoberturas
,',','"auditoria":', '"valorauditoria"',',','"tipodoc":',1,',','"porcentajesugerido":', elem.porcentajesugerido, '}');*/
    vparametro = concat('{','"cantidadpracticas":', 1,',','"idcapitulo":', '"',elem.idcapitulo ,'"',',','"idnomenclador":','"', elem.idnomenclador ,'"',','  ,'"idsubcapitulo":','"', elem.idsubcapitulo ,'"',',','"idpractica":','"', elem.idpractica ,'"',',','"idtempitem":', 'valor_vidtempitem',',','"idasocconv":', elem.idasocconv,',','"idplancoberturas":', elem.idplancoberturas
,',','"auditoria":', '"valorauditoria"',',','"tipodoc":',1,',','"porcentajesugerido":', elem.porcentajesugerido,',','"coberturaamuc":',elem.coberturaamuc, '}');  ----- BelenA - VAS 060525 el % de cob_amuc
     
      RAISE NOTICE 'desagrupar (vparametro,%)',vparametro;
  --  RAISE NOTICE '(elem.auditada,%)(elem.cantidadsolicitada,%)(elem.cantidadaprobada,%)',elem.auditada,elem.cantidadsolicitada,elem.cantidadaprobada;
   FOR vcontador IN 1..elem.cantidadsolicitada LOOP
    --    RAISE NOTICE '(vcontador,%)(elem.cantidadsolicitada,%)(elem.cantidadaprobada,%)',vcontador,elem.cantidadsolicitada,elem.cantidadaprobada;
        vidtempitem = vidtempitem + 1;
	IF vcontador <= elem.cantidadaprobada AND not elem.auditada THEN
		 
	   INSERT INTO tempitems (idtemitems,cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,porcentajesugerido,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc,tierror,iiimporteunitario, iicoberturaamuc, iicoberturasosuncexpendida) 
		VALUES(vidtempitem,1,elem.importeunitario,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,elem.idpractica,elem.idplancob,elem.auditada,elem.porcentaje,elem.porcentajesugerido,'','',''	,elem.amuc*1,elem.afiliado*1,elem.sosunc*1,'',elem.importeunitario,elem.coberturaamuc,(elem.porcentaje/100));

       

	ELSE
	   vparametro = CASE WHEN elem.cantidadaprobada = 0 THEN replace(vparametro,'valorauditoria','cantidad') ELSE 
			replace(vparametro,'valorauditoria','auditoria') END;  
           RAISE NOTICE 'else (vparametro,%)',vparametro;
           vparametro = replace(vparametro,'valor_vidtempitem',vidtempitem);
           RAISE NOTICE 'else (vparametro,%)',vparametro;
         --   RAISE NOTICE '(vparametro,%)',vparametro;
           SELECT INTO jsonitemaud * FROM w_emitirconsumoafiliado_auditoria(vparametro::jsonb);
	END IF;
         IF existecolumtemp('tempitems', 'idconfiguracion') THEN 
               UPDATE tempitems SET idconfiguracion = elem.idconfiguracion WHERE idtemitems = vidtempitem;
           END IF;

   END LOOP;

FETCH cpracticas INTO elem;
END LOOP;
CLOSE cpracticas;

 return respuestajson;

end;$function$
