CREATE OR REPLACE FUNCTION public.aefar_remitoestadotipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_remitoestadotipo(OLD);
        return OLD;
    END;
    $function$
