CREATE OR REPLACE FUNCTION public.aefar_obrasocialvalorescaja()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_obrasocialvalorescaja(OLD);
        return OLD;
    END;
    $function$
