CREATE OR REPLACE FUNCTION public.aereintegroprestacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreintegroprestacion(OLD);
        return OLD;
    END;
    $function$
