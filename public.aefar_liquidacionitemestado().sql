CREATE OR REPLACE FUNCTION public.aefar_liquidacionitemestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_liquidacionitemestado(OLD);
        return OLD;
    END;
    $function$
