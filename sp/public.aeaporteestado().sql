CREATE OR REPLACE FUNCTION public.aeaporteestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaporteestado(OLD);
        return OLD;
    END;
    $function$
