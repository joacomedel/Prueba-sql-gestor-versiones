CREATE OR REPLACE FUNCTION public.aefar_movimientostockitemordenventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostockitemordenventa(OLD);
        return OLD;
    END;
    $function$
