CREATE OR REPLACE FUNCTION public.amreintegroprestacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreintegroprestacion(NEW);
        return NEW;
    END;
    $function$
