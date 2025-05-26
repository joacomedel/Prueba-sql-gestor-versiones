CREATE OR REPLACE FUNCTION public.w_guardar_usuario(parametro jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

respuesta boolean;

BEGIN 
    -- Lo hacemos generico por si a futuro se quiere utilizar el WS para agregar el usuario a otras cosas
    IF (parametro->>'operacion' = 'emitirorden') THEN
    --RAISE EXCEPTION 'parametro->>data  %', parametro->>'data';
        PERFORM w_guardar_usuario_emitirorden( parametro );
    END IF;

   return respuesta; 
END;
$function$
