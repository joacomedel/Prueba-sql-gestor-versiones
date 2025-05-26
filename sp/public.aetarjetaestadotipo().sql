CREATE OR REPLACE FUNCTION public.aetarjetaestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctarjetaestadotipo(OLD);
        return OLD;
    END;
    $function$
