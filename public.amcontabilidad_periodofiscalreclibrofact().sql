CREATE OR REPLACE FUNCTION public.amcontabilidad_periodofiscalreclibrofact()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccontabilidad_periodofiscalreclibrofact(NEW);
        return NEW;
    END;
    $function$
