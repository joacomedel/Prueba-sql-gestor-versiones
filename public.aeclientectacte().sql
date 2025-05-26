CREATE OR REPLACE FUNCTION public.aeclientectacte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccclientectacte(OLD);
        return OLD;
    END;
    $function$
