CREATE OR REPLACE FUNCTION public.aerecibousuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecibousuario(OLD);
        return OLD;
    END;
    $function$
