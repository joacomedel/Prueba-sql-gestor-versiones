CREATE OR REPLACE FUNCTION public.controles_cantidadordenestipo_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_controles_cantidadordenestipo_contemporal 
AS (
	SELECT crdescripcion,case when idcentroregional = 1 AND tipo <> 56 THEN crdescripcion
        when idcentroregional = 1 AND tipo = 56 THEN concat(crdescripcion,'_online')
        else 'Delegaciones' END dondesale,t.* 
	,'1-Donde#dondesale@2-Centro Regional#crdescripcion@3-Tipo#ctdescripcion@4-Fecha#mesorden@5-Cant.Ordenes#cantidadordenes@6-Cant.Facturas#cantidadfacturas@7-Cant.Personas#cantidadpersonas@8-Importe Facturado#importe'::text as mapeocampocolumna
	FROM centroregional 
	NATURAL JOIN (
	
	select orden.centro as  idcentroregional,to_char(date_trunc( 'month', orden.fechaemision ),'MM-YYYY') as mesorden,orden.tipo,ctdescripcion,count(*) as cantidadordenes,count(distinct facturaventa.nrofactura) as cantidadfacturas,count(distinct consumo.nrodoc) as cantidadpersonas,sum(case when nullvalue(facturaventa.nrofactura) then 0 else importeefectivo end) as  importe
	from orden
        natural join consumo
        JOIN comprobantestipos ON tipo = idcomprobantetipos
        left join facturaorden using(nroorden,centro)
        left join facturaventa using(nrofactura,nrosucursal,tipofactura,centro)
 	where orden.fechaemision >= rfiltros.fechadesde AND orden.fechaemision <=  rfiltros.fechahasta and not anulado
        group by orden.centro,orden.tipo,ctdescripcion,to_char(date_trunc( 'month', orden.fechaemision ),'MM-YYYY')
) as t

);
     
--Para sacar el Resumen
--SELECT mesorden,dondesale,sum(cantidadordenes) as cantidadordenes,sum(cantidadfacturas) as cantidadfacturas,sum(cantidadpersonas) as cantidadpersonas,sum(importe) as importe
-- FROM temp_controles_cantidadordenestipo_contemporal
--group by mesorden,dondesale
--order by mesorden,dondesale;


return true;
END;
$function$
