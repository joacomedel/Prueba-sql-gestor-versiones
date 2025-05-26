CREATE OR REPLACE FUNCTION public.aefar_oviiformapago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_oviiformapago(OLD);
        return OLD;
    END;
    $function$
