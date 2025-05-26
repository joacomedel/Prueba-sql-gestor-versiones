CREATE OR REPLACE FUNCTION public.ctacte_generar_disponible()
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE
  		reg_descuento record;
BEGIN
		--- 1 - busco el menor disponible informado por la UNC
		-- 
		SELECT INTO reg_descuento *
		FROM ctasctesmontosdescuento
		WHERE  nullvalue(ccmdfechafin)
			  AND ccmdimporte > 0
	    ORDER BY ccmdimporte ASC
		LIMIT 1;
		
		--- 2 - Generar automaticamente losdisponibles para los 149 en base al menor monto informado por UNC
		INSERT INTO ctasctesmontosdescuento (nrodoc,	tipodoc,	ccmdimporte	,mesingreso,	anioingreso,	ccmdfechainicio,	ccmdfechafin,
											 ccmdmontoconsumido,	ccmdvigenciainicio,	ccmdvigenciafin,	idcentroctasctesmontosdescuento)(
		               SELECT nrodoc,	tipodoc,	reg_descuento.ccmdimporte	,reg_descuento.mesingreso,	reg_descuento.anioingreso,	reg_descuento.ccmdfechainicio,	reg_descuento.ccmdfechafin,
											 reg_descuento.ccmdmontoconsumido,	reg_descuento.ccmdvigenciainicio,	reg_descuento.ccmdvigenciafin,	reg_descuento.idcentroctasctesmontosdescuento
		               FROM persona 
		               WHERE barra=149 AND fechafinos >=current_date
		);
		
		return reg_descuento.ccmdimporte ;
		END;

$function$
