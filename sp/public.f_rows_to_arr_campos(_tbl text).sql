CREATE OR REPLACE FUNCTION public.f_rows_to_arr_campos(_tbl text)
 RETURNS SETOF text[]
 LANGUAGE plpgsql
AS $function$
BEGIN

RETURN QUERY EXECUTE '
SELECT ARRAY[' || (
        SELECT string_agg(quote_literal(attname) || '::text', ',')
        FROM   pg_catalog.pg_attribute 
        WHERE  attrelid = _tbl::regclass  -- valid, visible table name 
        AND    attnum > 0                 -- exclude tableoid & friends
        AND    attisdropped = FALSE       -- exclude dropped columns
        ) || ' ]
FROM   ' || _tbl::regclass;

END;
$function$
