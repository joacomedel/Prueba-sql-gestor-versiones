CREATE OR REPLACE FUNCTION public.aefar_validacionsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_validacionsosunc(OLD);
        return OLD;
    END;
    $function$
