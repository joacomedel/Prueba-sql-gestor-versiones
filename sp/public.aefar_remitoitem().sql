CREATE OR REPLACE FUNCTION public.aefar_remitoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_remitoitem(OLD);
        return OLD;
    END;
    $function$
