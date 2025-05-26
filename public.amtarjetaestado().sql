CREATE OR REPLACE FUNCTION public.amtarjetaestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctarjetaestado(NEW);
        return NEW;
    END;
    $function$
