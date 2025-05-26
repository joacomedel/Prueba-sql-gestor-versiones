CREATE OR REPLACE FUNCTION public.amfar_movimientostockitemfactventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostockitemfactventa(NEW);
        return NEW;
    END;
    $function$
