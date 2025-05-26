CREATE OR REPLACE FUNCTION public.amtarjetaestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctarjetaestadotipo(NEW);
        return NEW;
    END;
    $function$
