CREATE OR REPLACE FUNCTION public.amactasdefun()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccactasdefun(NEW);
        return NEW;
    END;
    $function$
