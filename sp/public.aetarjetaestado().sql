CREATE OR REPLACE FUNCTION public.aetarjetaestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctarjetaestado(OLD);
        return OLD;
    END;
    $function$
