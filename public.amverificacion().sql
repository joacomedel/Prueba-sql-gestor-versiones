CREATE OR REPLACE FUNCTION public.amverificacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccverificacion(NEW);
        return NEW;
    END;
    $function$
