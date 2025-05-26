CREATE OR REPLACE FUNCTION public.aecontabilidad_periodofiscalreclibrofact()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccontabilidad_periodofiscalreclibrofact(OLD);
        return OLD;
    END;
    $function$
