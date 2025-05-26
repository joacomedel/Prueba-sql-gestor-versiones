CREATE OR REPLACE FUNCTION public.aefar_ordenvalidaciones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenvalidaciones(OLD);
        return OLD;
    END;
    $function$
