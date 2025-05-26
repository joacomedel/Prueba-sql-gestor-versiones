CREATE OR REPLACE FUNCTION public.aecargo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccargo(OLD);
        return OLD;
    END;
    $function$
