CREATE OR REPLACE FUNCTION ca.empleadolicencia_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
        vquery varchar;
    
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_empleadolicencia_contemporal
AS (



select
idpersona,
idempleadogrupo,
egdescripcion,
penombre,
peapellido,
penrodoc,
tdnombre,
emlegajo,
sedescripcion,
idlicencia,
to_char(lifechainicio,'DD/mm/YYYY') as lifechainicio,
to_char(lifechafin,'DD/mm/YYYY') as lifechafin,
ltdescripcion,ca.cantidaddiassegunlicencia (lifechainicio, lifechafin, idlicenciatipo::integer) as dias
, '1-Apellido#peapellido@2-Nombres#penombre@3-NroDocumento#penrodoc@4-Legajo#emlegajo@5-Grupo#egdescripcion@6-Sector#sedescripcion@7-IdLicencia#idlicencia@8-FechaInicioLicencia#lifechainicio@9-FechaFinLicencia#lifechafin@10-CantidadDias#dias'::text as mapeocampocolumna 

from
ca.persona natural join
ca.empleado natural join
ca.empleadogrupo natural join
ca.tipodocumento natural join
ca.sector natural join
ca.licencia natural join
ca.licenciatipo
WHERE idpersona = rfiltros.nrodoc
order by peapellido, penombre, licencia.idlicenciatipo,licencia.lifechainicio);

return true;
END;$function$
