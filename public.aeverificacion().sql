CREATE OR REPLACE FUNCTION public.aeverificacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccverificacion(OLD);
        return OLD;
    END;
    $function$
