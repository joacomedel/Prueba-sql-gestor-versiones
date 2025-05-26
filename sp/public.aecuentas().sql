CREATE OR REPLACE FUNCTION public.aecuentas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentas(OLD);
        return OLD;
    END;
    $function$
