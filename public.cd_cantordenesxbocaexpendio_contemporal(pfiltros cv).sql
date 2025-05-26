CREATE OR REPLACE FUNCTION public.cd_cantordenesxbocaexpendio_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cd_cantordenesxbocaexpendio_contemporal
AS (
	
	
select   count(*)as cantidad,bocaexpendio,ctdescripcion,
	'1-Cantidad#cantidad@2-Emisor#bocaexpendio@3-TipoOrden#ctdescripcion'::text as mapeocampocolumna 
from
(
select orden.*,comprobantestipos.ctdescripcion,acdecripcion,crdescripcion
,case when tipo=56 then 'SUAP/EVWEB' else crdescripcion end as bocaexpendio
from
orden


join centroregional
on(orden.centro=idcentroregional)
left join ordenestados
using(nroorden,centro)
join comprobantestipos
on(idcomprobantetipos=tipo)
natural join asocconvenio

where fechaemision>= rfiltros.fechaemision
and nullvalue(ordenestados.nroorden)

) as j
group by bocaexpendio ,ctdescripcion,crdescripcion
order by bocaexpendio ,ctdescripcion,crdescripcion
  );

return true;
END;
$function$
