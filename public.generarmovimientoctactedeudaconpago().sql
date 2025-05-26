CREATE OR REPLACE FUNCTION public.generarmovimientoctactedeudaconpago()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
      ccorreo CURSOR FOR SELECT  *
                        FROM  temp_correo;
                       
	  elem RECORD;
	  rplanillacorreo RECORD;
      vresultado bigint;

BEGIN


return true;
END;
$function$
