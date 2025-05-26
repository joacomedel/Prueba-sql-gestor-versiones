CREATE OR REPLACE FUNCTION public.tesoreria_controlcaja_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
   rtfvliquidacioniva RECORD;
BEGIN

  IF NEW.idrecibo > 1000000000 THEN 
        perform tesoreria_controlcaja_vincularcomprobante(concat('{tipocomprobante=0,idrecibo=',NEW.idrecibo,' ,centro=',NEW.centro,'}'));
  END IF;
  RETURN NEW;
END;
$function$
