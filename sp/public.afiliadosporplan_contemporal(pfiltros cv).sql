CREATE OR REPLACE FUNCTION public.afiliadosporplan_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;
  relem RECORD;
  rfiltros record;


BEGIN
 
 
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 
CREATE TEMP TABLE temp_afiliadosporplan_contemporal
AS (
select plancobpersona.nrodoc,persona.barra,plancobpersona.pcpfechaingreso,
persona.nombres,persona.apellido,plancobertura.descripcion as plan ,estados.descrip as estado,persona.fechafinos,case when nullvalue(plancobpersona.pcpfechafin) then '' else plancobpersona.pcpfechafin::character varying end as pcpfechafin,
 '1-Nrodoc#nrodoc@2-Barra#barra@3-Apellido#apellido@4-Nombres#nombres@5-FechaFinOS#fechafinos@6-EstadoAfil#estado@7-Plan#plan@8-FechaIngresoPlan#pcpfechaingreso@9-FechaFinPlan#pcpfechafin'::text as mapeocampocolumna

from plancobpersona natural join plancobertura
natural join persona join
(
select nrodoc,tipodoc,idestado from
afilsosunc
union
select nrodoc,tipodoc,idestado from
benefsosunc
union
select nrodoc,tipodoc,idestado from
afilreci
union
select nrodoc,tipodoc,idestado from
benefreci
) as g
on (persona.tipodoc=g.tipodoc and persona.nrodoc=g.nrodoc)
join  estados using (idestado)
where (plancobertura.idplancobertura=rfiltros.idplancobertura or rfiltros.idplancobertura =0 )
and (estados.idestado<>4)
order by apellido, nombres
	
);
   


return true;
END;$function$
