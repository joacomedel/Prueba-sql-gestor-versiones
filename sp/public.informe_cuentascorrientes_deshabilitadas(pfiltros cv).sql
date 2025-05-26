CREATE OR REPLACE FUNCTION public.informe_cuentascorrientes_deshabilitadas(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rfiltros record;
        
	
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_informe_cuentascorrientes_deshabilitadas
	AS (
		SELECT nrodoc, concat(apellido,' ',nombres) as nombreafiliado, estadoctacte
                ,fechacambio, upfechafincambio, motivo

,'1-Nro.Documento#nrodoc@2-Nombre Afiliado#nombreafiliado@3-Estado Cta.Cte#estadoctacte@4-Fecha Inicio Estado#fechacambio@5-Fecha Fin Estado#upfechafincambio@6-Motivo#motivo'::text as mapeocampocolumna

                FROM usuariopersona
                LEFT JOIN persona USING (nrodoc, tipodoc)
                WHERE fechacambio>=rfiltros.fechadesde  
                AND ( nullvalue (upfechafincambio) OR upfechafincambio<=rfiltros.fechahasta ) 
                AND NOT nullvalue(estadoctacte)

                ORDER BY nrodoc, fechacambio asc

                  );

return true;
END;
$function$
