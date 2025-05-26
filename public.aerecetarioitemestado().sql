CREATE OR REPLACE FUNCTION public.aerecetarioitemestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetarioitemestado(OLD);
        return OLD;
    END;
    $function$
