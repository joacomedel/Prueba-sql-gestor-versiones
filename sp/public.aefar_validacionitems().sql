CREATE OR REPLACE FUNCTION public.aefar_validacionitems()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_validacionitems(OLD);
        return OLD;
    END;
    $function$
