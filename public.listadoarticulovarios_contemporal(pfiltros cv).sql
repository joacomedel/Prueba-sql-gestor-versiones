CREATE OR REPLACE FUNCTION public.listadoarticulovarios_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;

	-- GK 31/03/2021
	-- Filtros:
	-- 		- Rubro
	--		- Lab
	--		- Alfabeto 

BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
    
       CREATE TEMP TABLE temp_listadoarticulovarios_contemporal
   AS (

		 		SELECT 
		 			l.lnombre,
					fr.rdescripcion,
					fl.lstock,
					--fp.pavalor,
					--fp.pimporteiva,
					--fp.pvalorcompra,
					fa.adescripcion,
					fa.acodigobarra
				,'1-Laboratorio#lnombre@2-Descripcion#rdescripcion@3-Stock#lstock@4-Articulo#adescripcion@5-CodigoBarra#acodigobarra'::text as mapeocampocolumna

				FROM far_articulo as fa
				LEFT JOIN far_rubro fr USING (idrubro)
				LEFT JOIN far_lote as fl  ON (fa.idarticulo=fl.idarticulo  AND fa.idcentroarticulo=fl.idcentroarticulo and  fl.idcentrolote=centro()) 
				LEFT JOIN far_precioarticulo as fp ON (fa.idarticulo=fp.idarticulo AND fa.idcentroarticulo=fp.idcentroarticulo)
				LEFT JOIN far_medicamento as fm  ON (fa.idarticulo=fm.idarticulo AND fa.idcentroarticulo=fm.idcentroarticulo)
 				LEFT JOIN medicamento as m USING (mnroregistro)
 				LEFT JOIN laboratorio as l USING(idlaboratorio)

				WHERE true
				AND aactivo
				--AND NOT apreciokairos
				AND (CASE WHEN NOT (nullvalue(rfiltros.cantidad) AND rfiltros.cantidad<>0) THEN  
						(CASE WHEN rfiltros.cantidad >0
						THEN  lstock >= rfiltros.cantidad 
						ELSE lstock <= rfiltros.cantidad END)
					ELSE
						lstock<>0
					END)
				AND nullvalue(pafechafin)
				AND (nullvalue(rfiltros.idrubro) OR idrubro=rfiltros.idrubro)
				AND (nullvalue(rfiltros.idlaboratorio) OR idlaboratorio=rfiltros.idlaboratorio)
				--AND (rfiltros.alfabeto='' OR adescripcion ilike concat(''',rfiltros.alfabeto,'%','''))

				ORDER BY adescripcion

       );
  
return true;
END;
$function$
