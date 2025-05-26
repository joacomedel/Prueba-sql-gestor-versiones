CREATE OR REPLACE FUNCTION public.configuracion_aportejubpen_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_configuracion_aportejubpen_contemporal
--CREATE  TABLE temp_configuracion_aportejubpen_contemporal_malapi
AS (
select 
apellido,nombres,
persona.nrodoc,
concat(persona.nrodoc ,' - ',persona.barra) as nroafiliado,
fechafinos,
telefono,
email,    
round(acimportebruto::numeric,2) as acimportebruto,
concat(persona.apellido ,', ',persona.nombres) as nomapeafiliado,
acfechainicio as ultimaactualizacion,
round(acporcentaje::numeric,2) as acporcentaje, 
round(acimporteaporte::numeric,2) as acimporteaporte
, '1-Apellido#apellido@2-Nombres#nombres@3-NroAfiliado#nroafiliado@4-FechaFinOS#fechafinos@5-Telefono#telefono@6-Email#email@7-ImporteBruto#acimportebruto@8-NomApeAfiliado#nomapeafiliado@9-UltimaActualizacion#ultimaactualizacion@10-Porcentaje#acporcentaje@11-ImporteAporteB#acimporteaporte'::text as mapeocampocolumna 
   
 from  persona
 join aporteconfiguracion on(persona.nrodoc=aporteconfiguracion.nrodoc and
 persona.tipodoc=aporteconfiguracion.tipodoc and nullvalue(acfechafin))
where  nullvalue(acfechafin) and persona.fechafinos>=rfiltros.fechafinos
and (barra=35 or barra=36)
order by apellido,nombres

);
     

return true;
END;
$function$
