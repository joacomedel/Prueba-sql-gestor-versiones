CREATE OR REPLACE FUNCTION public.aerecepcion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecepcion(OLD);
        return OLD;
    END;
    $function$
