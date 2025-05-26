CREATE OR REPLACE FUNCTION public.listado_sin_aportes_conyuge_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_listado_sin_aportes_conyuge_contemporal
AS (
     SELECT *, 
   '1-legajosiu#legajosiu@2-nrodoctitu#nrodoctitu@3-barratitu#barratitu@4-Mes Aporte#Mes Aporte@5-Nombre Titular#Nombre Titular@6-Apellido Titular#Apellido Titular@7-nrodoc#nrodoc@8-barra#barra@9-nombres#nombres@10-apellido#apellido@11-descrip#descrip@12-fechafinos#fechafinos'::text as mapeocampocolumna  FROM(

	select  distinct(legajosiu)  , nrodoctitu, barratitu, rfiltros.mes as "Mes Aporte",
 p.nombres as "Nombre Titular",  p.apellido as "Apellido Titular",
 persona.nrodoc, persona.barra, persona.nombres, persona.apellido, descrip , persona.fechafinos
 from persona  
 left join benefsosunc on (benefsosunc.nrodoc = persona.nrodoc)
 left join cargo on (nrodoctitu = cargo.nrodoc)
 left join vinculos using(idvin)
 left join persona as p on (nrodoctitu = p.nrodoc)
 where persona.barra = 1 

  and  persona.fechafinos >= date(date_trunc('month', concat(rfiltros.anio,'-',rfiltros.mes,'-01')::date + interval '1 month'))
  and barratitu in (30,31,33,37)

  and legajosiu not in (SELECT 
nrolegajo  
FROM dh21
where mesingreso=rfiltros.mes
 and anioingreso=rfiltros.anio
 and nroconcepto = 392
group by nrolegajo)
	

)as taportes);
  

return true;
END;$function$
