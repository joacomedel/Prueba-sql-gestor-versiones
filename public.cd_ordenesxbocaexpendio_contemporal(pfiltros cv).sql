CREATE OR REPLACE FUNCTION public.cd_ordenesxbocaexpendio_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cd_ordenesxbocaexpendio_contemporal
AS (
	
	

	
select   count(*)as cantidad,bocaexpendio,ctdescripcion,idnomenclador,idcapitulo,idsubcapitulo,idpractica
,	'1-Cantidad#cantidad@2-Emisor#bocaexpendio@3-TipoOrden#ctdescripcion@4-Nomenclador#idnomenclador@5-Capitulo#idcapitulo@6-Subcapitulo#idsubcapitulo@7-Practica#idpractica'::text as mapeocampocolumna
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
     (select  nroorden,centro,idnomenclador,idcapitulo,idsubcapitulo,idpractica
        from ordvalorizada
           natural join itemvalorizada
          natural join item 
           natural join practica
      ) as t
join comprobantestipos
on(idcomprobantetipos=tipo)
natural join asocconvenio

where fechaemision>=rfiltros.fechaemision
and nullvalue(ordenestados.nroorden)

) as j
group by bocaexpendio ,ctdescripcion,crdescripcion,idnomenclador,idcapitulo,idsubcapitulo,idpractica
order by bocaexpendio ,ctdescripcion,crdescripcion,idnomenclador,idcapitulo,idsubcapitulo,idpractica
  );

return true;
END;
$function$
