CREATE OR REPLACE FUNCTION public.w_sosunc_devolver_entrada(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$declare

respuestajson jsonb;

BEGIN 
    respuestajson=parametro;


   return respuestajson; 
END;
$function$
