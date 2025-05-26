CREATE OR REPLACE FUNCTION public.cd_ordenesconordinternacion_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cd_ordenesconordinternacion_contemporal
AS (
	

select count(*) as cantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,
'1-Cantidad#cantidad@2-Nomenclador#idnomenclador@3-Capitulo#idcapitulo@4-Subcapitulo#idsubcapitulo@5-Practica#idpractica@6-Descripcion#pdescripcion'::text as mapeocampocolumna
from
orden
join centroregional
on(orden.centro=idcentroregional)
left join ordenestados
using(nroorden,centro)
natural join
(   
select  nroorden,centro,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion
    	from ordvalorizada
       	natural join itemvalorizada
      	natural join item
       	natural join practica
)as q
where fechaemision>=rfiltros.fechadesde
and nullvalue(ordenestados.nroorden)
and not nullvalue(nroordeninter)
 and not nullvalue(centroordeninter)
group by idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion
order by cantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion
 
  );

return true;
END;
$function$
