CREATE OR REPLACE FUNCTION public.turismo_excelvaloresvigentes_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
	rfiltros RECORD;
       
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
CREATE TEMP TABLE temp_turismo_excelvaloresvigentes_contemporal
AS (
	SELECT tuztdescripcion,tadescripcion, tudescripcion, turismounidadtipo.tutdescripcion, concat(idturismotemporadatipos,'-',tttdescripcion) as elturismotemporadatipos,
       concat(idturismounidadvalortipo,'-',tuvtdescripcion) as elturismounidadvalortipo,
       tuvfechaini, tuvfechfin  as tuvfechafin, tuvimporteafiliado, tuvimporteinvitado, tuvimportesosunc, tuvimporteinvitadososunc as tuvinvitadososunc,tuvporpersona      
   ,'1-Zona#tuztdescripcion@2-Administrador#tadescripcion@3-Unidades#tudescripcion@4-Temporada#elturismotemporadatipos@5-Tipo Unidad#elturismounidadvalortipo@6-Fecha Inicio#tuvfechaini@7-Fecha Fin#tuvfechafin@8-Imp.Afiliado#tuvimporteafiliado@9-Imp.X Invitado#tuvimporteinvitado@10-Imp.Sosunc#tuvimportesosunc@11-Imp.X Invitado Sosunc#tuvinvitadososunc@12-X Persona#tuvporpersona' as mapeocampocolumna
    
FROM turismoadmin NATURAL JOIN turismounidad  NATURAL JOIN turismounidadvalor NATURAL JOIN  turismotemporadatipos NATURAL JOIN turismounidadvalortipo   NATURAL JOIN turismounidadzonatipo
NATURAL  JOIN turismounidadtipo 
WHERE tuvtactivo AND tuztactivo AND (nullvalue(turismounidadvalor.tuvfechfin) OR turismounidadvalor.tuvfechfin >= current_date )  
        and  tuvfechaini>= rfiltros.fechaini
);
     

return 'Ok';
END;
$function$
