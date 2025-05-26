CREATE OR REPLACE FUNCTION public.w_sosunc_emitirconsumoafiliado_procesarentrada(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$declare

respuestajson jsonb;
aux character varying;
rorden RECORD;
 
array_resultado jsonb[];
unelemento jsonb;

BEGIN 
    --RAISE EXCEPTION ' aaaaaaav parametro % ',parametro;

  IF parametro->>'respuesta' = 'true'  THEN  --Hay un error

           array_resultado := ARRAY(SELECT jsonb_array_elements_text(parametro->'resultado'));

        respuestajson := array_resultado[1]::jsonb;
           /*FOREACH unelemento  IN ARRAY array_resultado LOOP 
                      SELECT INTO rorden * 
                      FROM  orden 
                      NATURAL JOIN ordenrecibo 
                      WHERE nroorden = unelemento->>'nroorden'  AND centro = unelemento->>'centro' ;
                      respuestajson = row_to_json(rorden);
           END LOOP;*/

  END IF;

   return respuestajson; 
END;

$function$
