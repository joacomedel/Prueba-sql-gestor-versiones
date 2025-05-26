CREATE OR REPLACE FUNCTION public.amingresosusuarios()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccingresosusuarios(NEW);
        return NEW;
    END;
    $function$
