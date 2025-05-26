CREATE OR REPLACE FUNCTION public.aefar_validacionxml()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_validacionxml(OLD);
        return OLD;
    END;
    $function$
