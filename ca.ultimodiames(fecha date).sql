CREATE OR REPLACE FUNCTION ca.ultimodiames(fecha date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
    eldia integer;
BEGIN

    select INTO eldia   extract(DAY from ((date_trunc('month', fecha::timestamp) + interval '1 month') - interval '1 day')::date);
    RETURN eldia;
END;
$function$
