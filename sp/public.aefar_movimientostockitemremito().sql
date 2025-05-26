CREATE OR REPLACE FUNCTION public.aefar_movimientostockitemremito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostockitemremito(OLD);
        return OLD;
    END;
    $function$
