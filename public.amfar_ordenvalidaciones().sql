CREATE OR REPLACE FUNCTION public.amfar_ordenvalidaciones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenvalidaciones(NEW);
        return NEW;
    END;
    $function$
