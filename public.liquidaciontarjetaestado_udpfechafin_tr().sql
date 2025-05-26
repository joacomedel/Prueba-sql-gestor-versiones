CREATE OR REPLACE FUNCTION public.liquidaciontarjetaestado_udpfechafin_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  
BEGIN
	UPDATE liquidaciontarjetaestado 
		SET ltefechafin = CURRENT_DATE
	WHERE idliquidaciontarjeta = NEW.idliquidaciontarjeta AND idcentroliquidaciontarjeta = NEW.idcentroliquidaciontarjeta and nullvalue(ltefechafin);
RETURN NEW;
END;
$function$
