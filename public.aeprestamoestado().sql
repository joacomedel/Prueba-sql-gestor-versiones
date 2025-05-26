CREATE OR REPLACE FUNCTION public.aeprestamoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestamoestado(OLD);
        return OLD;
    END;
    $function$
