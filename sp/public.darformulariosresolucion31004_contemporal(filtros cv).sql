CREATE OR REPLACE FUNCTION public.darformulariosresolucion31004_contemporal(filtros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

rfiltros record;

BEGIN

EXECUTE sys_dar_filtros(filtros) INTO rfiltros;

-- mostrar fila por item de solicitud
if rfiltros.mostrarfilapor = 2 then
	CREATE TEMP TABLE temp_darformulariosresolucion31004_contemporal AS
	SELECT safechaingreso,idsolicitudauditoria,sadiagnostico,p.nrodoc,p.tipodoc,p.apellido as apellido_afil,p.nombres as nombres_afil,usu.nombre as nombres_audit, usu.apellido as apellido_audit,saeobservacion
	FROM solicitudauditoria as afi NATURAL JOIN solicitudauditoriaitem NATURAL JOIN solicitudauditoriaitem_ext  NATURAL JOIN solicitudauditoriaestado JOIN usuario as usu ON(saeidusuario = idusuario) JOIN persona AS p ON(p.nrodoc =afi.nrodoc and p.tipodoc = afi.tipodoc)
	WHERE saefechafin IS NULL
	ORDER BY  safechaingreso ASC;
end if;

--mostrar item por solicitud
if rfiltros.mostrarfilapor = 1 then
	CREATE TEMP TABLE temp_darformulariosresolucion31004_contemporal AS
	SELECT safechaingreso,idsolicitudauditoria,sadiagnostico,p.nrodoc,p.tipodoc,p.apellido as apellido_afil,p.nombres as nombres_afil,usu.nombre as nombres_audit, usu.apellido as apellido_audit,saeobservacion
	FROM solicitudauditoria as afi NATURAL JOIN solicitudauditoriaitem NATURAL JOIN solicitudauditoriaitem_ext  NATURAL JOIN solicitudauditoriaestado JOIN usuario as usu ON(saeidusuario = idusuario) JOIN persona AS p ON(p.nrodoc =afi.nrodoc and p.tipodoc = afi.tipodoc)
	WHERE saefechafin IS NULL
	GROUP BY safechaingreso,idsolicitudauditoria,sadiagnostico,p.nrodoc,p.tipodoc,apellido_afil,nombres_afil,nombres_audit,apellido_audit,saeobservacion
	ORDER BY  safechaingreso ASC;
end if;

return true;

END;
$function$
