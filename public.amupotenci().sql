CREATE OR REPLACE FUNCTION public.amupotenci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccupotenci(NEW);
        return NEW;
    END;
    $function$
