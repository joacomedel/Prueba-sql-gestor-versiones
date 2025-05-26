CREATE OR REPLACE FUNCTION public.aefar_obrasocialmutual()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_obrasocialmutual(OLD);
        return OLD;
    END;
    $function$
