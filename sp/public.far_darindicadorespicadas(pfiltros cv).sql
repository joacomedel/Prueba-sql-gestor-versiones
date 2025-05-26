CREATE OR REPLACE FUNCTION public.far_darindicadorespicadas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD 
rfiltros RECORD;
--VARCHAR
vcantidiferencia INTEGER;
vcantpicados INTEGER;
vcantactivosfarma INTEGER;
vidstockajuste VARCHAR;

BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
vidstockajuste = CASE WHEN nullvalue(rfiltros.idstockajuste) THEN null WHEN rfiltros.idstockajuste::varchar='null' THEN null ELSE rfiltros.idstockajuste::varchar END; 
RAISE NOTICE 'vidstockajuste (%)',vidstockajuste;
RAISE NOTICE 'nullvalue(vidstockajuste) (%)',nullvalue(vidstockajuste);

SELECT INTO vcantidiferencia COUNT(1) as cantdiferencia 
FROM (
SELECT idarticulo,idcentroarticulo,sum(psaicantidadcontada) as psaicantidadcontada,(CASE WHEN nullvalue(min(psaistocksistema)) THEN far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo)	ELSE   min(psaistocksistema) END) as stockactual
FROM far_precargastockajusteitem  as t
WHERE not psaiborrado AND CASE WHEN nullvalue(vidstockajuste) THEN nullvalue(idstockajuste)  ELSE vidstockajuste =idstockajuste END
GROUP BY idarticulo,idcentroarticulo,psaiidusuario
) as recuento NATURAL JOIN far_articulo
WHERE true and stockactual <> psaicantidadcontada;

SELECT INTO vcantpicados COUNT(1) as cantpicados 
FROM (
SELECT idarticulo,idcentroarticulo,sum(psaicantidadcontada) as psaicantidadcontada,(CASE WHEN nullvalue(min(psaistocksistema)) THEN far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo)	ELSE   min(psaistocksistema)   END)   as stockactual
FROM far_precargastockajusteitem  as t
WHERE not psaiborrado AND CASE WHEN nullvalue(vidstockajuste) THEN nullvalue(idstockajuste)  ELSE vidstockajuste =idstockajuste END
GROUP BY idarticulo,idcentroarticulo,psaiidusuario
) as recuento NATURAL JOIN far_articulo ;

SELECT INTO vcantactivosfarma far_cantidadarticuloactivos('')::BIGINT;

RETURN  concat(vcantidiferencia,'-',vcantpicados,'-',vcantactivosfarma );

END;$function$
