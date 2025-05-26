CREATE OR REPLACE FUNCTION public.amconsumorecetarioreciprocidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconsumorecetarioreciprocidad(NEW);
        return NEW;
    END;
    $function$
