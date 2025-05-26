CREATE OR REPLACE FUNCTION public.amordinternacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordinternacion(NEW);
        return NEW;
    END;
    $function$
