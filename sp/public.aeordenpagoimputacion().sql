CREATE OR REPLACE FUNCTION public.aeordenpagoimputacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenpagoimputacion(OLD);
        return OLD;
    END;
    $function$
