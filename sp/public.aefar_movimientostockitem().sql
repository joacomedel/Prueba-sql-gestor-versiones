CREATE OR REPLACE FUNCTION public.aefar_movimientostockitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostockitem(OLD);
        return OLD;
    END;
    $function$
