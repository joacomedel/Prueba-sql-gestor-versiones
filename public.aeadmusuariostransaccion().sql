CREATE OR REPLACE FUNCTION public.aeadmusuariostransaccion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccadmusuariostransaccion(OLD);
        return OLD;
    END;
    $function$
