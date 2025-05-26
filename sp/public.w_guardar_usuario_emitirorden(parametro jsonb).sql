CREATE OR REPLACE FUNCTION public.w_guardar_usuario_emitirorden(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

jsondata jsonb;

respuesta boolean;

raux record;
BEGIN 

    jsondata= (parametro->>'data');
    
    UPDATE recibousuario
    SET idusuario = (parametro->>'idusuario')::bigint
    WHERE idrecibo = (jsondata->>'idrecibo')::bigint 
        AND centro = (jsondata->>'centro')::integer;

   return respuesta; 
END;
$function$
