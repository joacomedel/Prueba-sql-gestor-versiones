CREATE OR REPLACE FUNCTION public.f_dar_valores_comprar()
 RETURNS SETOF double precision[]
 LANGUAGE plpgsql
AS $function$
BEGIN

RETURN QUERY EXECUTE '
SELECT ARRAY[' || (
       SELECT string_agg(quote_ident(attname) || '::float', ',')
        FROM   pg_catalog.pg_attribute 
        WHERE  attrelid = 'comparacion_valores_practica'::regclass  
        AND     attname ilike 'col%'
        AND    attnum > 0                
        AND    attisdropped = FALSE   
        ) || ' ]
FROM   ' || 'comparacion_valores_practica'::regclass
|| ' WHERE pdescripcion not ilike ''Referencias %'' ';

END;
$function$
