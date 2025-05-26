CREATE OR REPLACE FUNCTION public.listadoarticulopreciosnokairo_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
    
       CREATE TEMP TABLE temp_listadoarticulopreciosnokairo_contemporal
   AS (

		 		SELECT 
					fp.pamodificacion,
					fl.lstock,
					--fp.pavalor,
					--fp.pimporteiva,
					fp.pvalorcompra,
					fa.adescripcion,
					fa.acodigobarra
				,'1-FechaModificacion#pamodificacion@2-Stock#lstock@3-Articulo#adescripcion@4-Valor#pvalorcompra@5-CodigoBarra#acodigobarra'::text as mapeocampocolumna

				FROM far_articulo as fa
				LEFT JOIN far_lote as fl  ON (fa.idarticulo=fl.idarticulo  AND fa.idcentroarticulo=fl.idcentroarticulo and  fl.idcentrolote=centro()) 
				LEFT JOIN far_precioarticulo as fp ON (fa.idarticulo=fp.idarticulo AND fa.idcentroarticulo=fp.idcentroarticulo)
				


				WHERE true
				AND aactivo
				AND NOT apreciokairos
				AND lstock >0
				AND nullvalue(pafechafin)
				AND (nullvalue(rfiltros.fechadesde) OR rfiltros.fechadesde<= pamodificacion)
				AND (nullvalue(rfiltros.fechahasta) OR rfiltros.fechahasta>= pamodificacion)

				ORDER BY adescripcion


       );
  
return true;
END;
$function$
