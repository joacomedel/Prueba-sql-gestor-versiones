CREATE OR REPLACE FUNCTION public.aemutualpadronestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmutualpadronestado(OLD);
        return OLD;
    END;
    $function$
