CREATE OR REPLACE FUNCTION public.aeusuarioconfiguracion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccusuarioconfiguracion(OLD);
        return OLD;
    END;
    $function$
