CREATE OR REPLACE FUNCTION public.aefar_vendedor()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_vendedor(OLD);
        return OLD;
    END;
    $function$
