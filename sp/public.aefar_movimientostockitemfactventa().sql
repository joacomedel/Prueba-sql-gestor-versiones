CREATE OR REPLACE FUNCTION public.aefar_movimientostockitemfactventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostockitemfactventa(OLD);
        return OLD;
    END;
    $function$
