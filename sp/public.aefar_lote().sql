CREATE OR REPLACE FUNCTION public.aefar_lote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_lote(OLD);
        return OLD;
    END;
    $function$
