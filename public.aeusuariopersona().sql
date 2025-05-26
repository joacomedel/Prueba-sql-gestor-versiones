CREATE OR REPLACE FUNCTION public.aeusuariopersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccusuariopersona(OLD);
        return OLD;
    END;
    $function$
