CREATE OR REPLACE FUNCTION public.cd_ordenesxbocaexpendioxplan_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cd_ordenesxbocaexpendioxplan_contemporal
AS (
	
	

	
select   count(*)as cantidad,bocaexpendio,ctdescripcion,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,descripcion
 ,	'1-Cantidad#cantidad@2-Emisor#bocaexpendio@3-TipoOrden#ctdescripcion@4-Nomenclador#idnomenclador@5-Capitulo#idcapitulo@6-Subcapitulo#idsubcapitulo@7-Practica#idpractica@8-DescripcionPractica#pdescripcion@9-PlanCobertura#descripcion'::text as mapeocampocolumna
from
(
select orden.*,comprobantestipos.ctdescripcion,acdecripcion,crdescripcion
,case when tipo=56 then 'SUAP/EVWEB' else crdescripcion end as bocaexpendio,t.*
from
orden


join centroregional
on(orden.centro=idcentroregional)
left join ordenestados
using(nroorden,centro)
natural join
     (select  nroorden,centro,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,descripcion
        from ordvalorizada
           natural join itemvalorizada
          natural join item 
           natural join practica
join plancobertura on(idplancobertura=idplancovertura)
      ) as t
join comprobantestipos
on(idcomprobantetipos=tipo)
natural join asocconvenio

where fechaemision>=rfiltros.fechadesde
and nullvalue(ordenestados.nroorden)

) as j
group by bocaexpendio ,ctdescripcion,crdescripcion,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,descripcion
order by bocaexpendio ,ctdescripcion,crdescripcion,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,descripcion
  );

return true;
END;
$function$
