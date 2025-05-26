CREATE OR REPLACE FUNCTION public.aetamanos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctamanos(OLD);
        return OLD;
    END;
    $function$
