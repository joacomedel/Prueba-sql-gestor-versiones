CREATE OR REPLACE FUNCTION public.afiliadosporplandisc_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;
  relem RECORD;
  rfiltros record;

BEGIN
 
 
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 
CREATE TEMP TABLE temp_afiliadosporplandisc_contemporal
AS (
select plancobpersona.nrodoc,persona.barra,plancobpersona.pcpfechaingreso,
persona.nombres,persona.apellido,plancobertura.descripcion as plan ,estados.descrip as estado,persona.fechafinos,
	case when nullvalue(plancobpersona.pcpfechafin) then '' else plancobpersona.pcpfechafin::character varying end as pcpfechafin,
	 age(fechanac)   as edad,idcertdiscapacidad,idcentrocertificadodiscapacidad,iddisc,nrocertificado,fechavtodisc,entemitecert,porcentdisc,juntacertificadora,acompanante,cif,idusuario,fechainiciodisc,discapacidad.descrip,porcentcober,dactivo,destaactivo,idcie10,
 '1-Nrodoc#nrodoc@2-Barra#barra@3-Apellido#apellido@4-Nombres#nombres@5-FechaFinOS#fechafinos@6-EstadoAfil#estado@7-Plan#plan@8-FechaIngresoPlan#pcpfechaingreso@9-FechaFinPlan#pcpfechafin@10-Edad#edad@11-idcertdiscapacidad#idcertdiscapacidad@12-idcentrocertificadodiscapacidad#idcentrocertificadodiscapacidad@13-iddisc#iddisc@14-nrocertificado#nrocertificado@15-fechavtodisc#fechavtodisc@16-entemitecert#entemitecert@17-porcentdisc#porcentdisc@18-juntacertificadora#juntacertificadora@19-acompanante#acompanante@20-cif#cif@21-idusuario#idusuario@22-fechainiciodisc#fechainiciodisc@23-descrip#descrip@24-porcentcober#porcentcober@25-dactivo#dactivo@26-destaactivo#destaactivo@27-idcie10#idcie10'::text as mapeocampocolumna
/*@25-dactivo@#dactivo@26-destaactivo#destaactivo@27-idcie10#idcie10'::text as mapeocampocolumna*/




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
	
JOIN certificadodiscapacidad as c 
on(c.nrodoc=persona.nrodoc and c.tipodoc=persona.tipodoc )
 JOIN discapacidad using(iddisc)
NATURAL JOIN cie10_certificadodiscapacidad as c10	
	
where 
--(plancobertura.idplancobertura=rfiltros.idplancobertura or rfiltros.idplancobertura =0 )
plancobertura.idplancobertura=13 and 
pcpfechaingreso >=rfiltros.fechadesde AND pcpfechaingreso <=rfiltros.fechahasta 
and (estados.idestado<>4) and fechavtodisc>current_date
order by apellido, nombres
	
);
   

return true;
END;$function$
