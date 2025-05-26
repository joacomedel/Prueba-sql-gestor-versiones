CREATE OR REPLACE FUNCTION public.w_pruebaws(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$

DECLARE
      
       respuesta character varying;
       respuestajson jsonb;
begin
      respuesta = 'Pepe';
      select INTO respuestajson parametro;
      --from parametro;
      --SELECT INTO respuestajson * FROM my_table_json LIMIT 1;
	IF (respuestajson->>'error' = 'si') THEN 
              RAISE EXCEPTION 'esto es un error  %',parametro;
              --RAISE NOTICE 'esto es un error  %',parametro;
         END IF;
      return respuestajson;

end;
$function$
