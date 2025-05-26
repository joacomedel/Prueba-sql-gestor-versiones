CREATE OR REPLACE FUNCTION public.aefar_remitoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_remitoestado(OLD);
        return OLD;
    END;
    $function$
