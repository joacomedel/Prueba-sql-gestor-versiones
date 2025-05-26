CREATE OR REPLACE FUNCTION public.aetarjeta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctarjeta(OLD);
        return OLD;
    END;
    $function$
