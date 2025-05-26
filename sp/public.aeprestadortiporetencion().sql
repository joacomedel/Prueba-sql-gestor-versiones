CREATE OR REPLACE FUNCTION public.aeprestadortiporetencion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestadortiporetencion(OLD);
        return OLD;
    END;
    $function$
