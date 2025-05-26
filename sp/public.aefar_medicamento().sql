CREATE OR REPLACE FUNCTION public.aefar_medicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_medicamento(OLD);
        return OLD;
    END;
    $function$
