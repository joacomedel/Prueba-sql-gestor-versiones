CREATE OR REPLACE FUNCTION public.aeusuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccusuario(OLD);
        return OLD;
    END;
    $function$
