CREATE OR REPLACE FUNCTION public.aecondicioniva()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccondicioniva(OLD);
        return OLD;
    END;
    $function$
