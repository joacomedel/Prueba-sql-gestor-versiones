CREATE OR REPLACE FUNCTION public.aeasientoimputacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccasientoimputacion(OLD);
        return OLD;
    END;
    $function$
