CREATE OR REPLACE FUNCTION public.rrhh_reportefichadaempleados_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--CURSOR
     cjornadaempleado refcursor;
--RECORD	
     rfiltros record;
     rjornadaempleado record;

	
BEGIN

	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
	CREATE TEMP TABLE temp_rrhh_reportefichadaempleados_contemporal
	AS ( 
		SELECT DISTINCT mofecha, amhora, concat(penombre,' ',peapellido) as elempleado, emlegajo, penrodoc, jhhorainicio, jhhorafin, CASE WHEN  amhora>(jhhorainicio +( interval '59 second')) THEN 'SI' ELSE 'NO' END AS tarde, ammotivo
,'1-Fecha Fichada#mofecha@2-Horario Inicio Jornada#jhhorainicio@3-Empleado#elempleado@4-Legajo#emlegajo@5-Nro. Doc#penrodoc@6-Fichado Ingreso#amhora@7-Tarde#tarde@8-Motivo#ammotivo' as mapeocampocolumna
		FROM ca.auditoriamovimiento NATURAL JOIN ca.movimientos NATURAL JOIN ca.persona  NATURAL JOIN ca.tipodocumento  NATURAL JOIN ca.empleado NATURAL JOIN ca.jornada  NATURAL JOIN ca.jornadahorario  
		WHERE  amfecha = rfiltros.fechafichada AND jorfechainicio<= rfiltros.fechafichada AND jorfechafin>rfiltros.fechafichada AND jhdia=date_part('dow',rfiltros.fechafichada::date)+1 
		/*KR Por ahora solo controlo la entrada*/
                AND idmovimientotipo= 1  AND NULLVALUE(amfechamodificacionfin) 
		ORDER BY elempleado
		);
       OPEN cjornadaempleado FOR SELECT  * FROM  temp_rrhh_reportefichadaempleados_contemporal;
       FETCH cjornadaempleado into rjornadaempleado;
       WHILE FOUND LOOP
            IF rfiltros.idtipofichada=1 AND  rjornadaempleado.amhora<=rjornadaempleado.jhhorainicio  THEN --Me interesan las llegadas tarde, Si el empleado cumple el horario de alguna jornada no llega tarde
                 DELETE FROM temp_rrhh_reportefichadaempleados_contemporal WHERE penrodoc = rjornadaempleado.penrodoc;
       
            END IF;

       FETCH cjornadaempleado INTO rjornadaempleado;
       END LOOP;
       CLOSE cjornadaempleado;
   	

RETURN 'true';
END;$function$
