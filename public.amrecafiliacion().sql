CREATE OR REPLACE FUNCTION public.amrecafiliacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecafiliacion(NEW);
        return NEW;
    END;
    $function$
