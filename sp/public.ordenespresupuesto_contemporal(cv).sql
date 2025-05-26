CREATE OR REPLACE FUNCTION public.ordenespresupuesto_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN
     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  
CREATE TEMP TABLE temp_ordenespresupuesto_contemporal AS (
 
select  
orden.nroorden,orden.centro,fechaemision::date,nrodoc,barra,apellido,nombres
idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,
importesorden.importe,'1-Orden#nroorden@2-Centro#centro@3-Fechaemision#fechaemision@4-Nrodoc#nrodoc@5-Barra#barra@6-Apellido#apellido@7-Nombres#nombres@8-Nomenclador#idnomenclador@9-Capitulo#idcapitulo@10-Subcapitulo#idsubcapitulo@11-Practica#idpractica@12-Descripcion#pdescripcion@13-Importe#importe'::text as mapeocampocolumna 


from 


orden
natural join importesorden
natural join consumo
natural join persona
natural join ordvalorizada
natural join itemvalorizada
natural join item
natural join practica
left join ordenestados
on(ordenestados.nroorden=orden.nroorden and ordenestados.centro=orden.centro)


where 
(fechaemision>=rparam.fechadesde )
and
(fechaemision<=rparam.fechahasta or rparam.fechahasta is null)	
	
--and 1563503=orden.nroorden
and tipo=20
and nullvalue(ordenestados.nroorden)
order by fechaemision,orden.centro 
       
);
  
 
 respuesta = 'todook';    
      
    
return respuesta;
END;$function$
