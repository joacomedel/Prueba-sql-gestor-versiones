CREATE OR REPLACE FUNCTION public.aefar_rubro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_rubro(OLD);
        return OLD;
    END;
    $function$
