CREATE OR REPLACE FUNCTION public.aecmitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccmitem(OLD);
        return OLD;
    END;
    $function$
