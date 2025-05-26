CREATE OR REPLACE FUNCTION public.aefar_ordenventaliquidacionauditada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventaliquidacionauditada(OLD);
        return OLD;
    END;
    $function$
