CREATE OR REPLACE FUNCTION public.aefar_obrasocial()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_obrasocial(OLD);
        return OLD;
    END;
    $function$
