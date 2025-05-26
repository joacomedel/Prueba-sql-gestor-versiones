CREATE OR REPLACE FUNCTION public.aeconsumorecetarioreciprocidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconsumorecetarioreciprocidad(OLD);
        return OLD;
    END;
    $function$
