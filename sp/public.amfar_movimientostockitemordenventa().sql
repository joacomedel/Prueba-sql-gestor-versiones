CREATE OR REPLACE FUNCTION public.amfar_movimientostockitemordenventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostockitemordenventa(NEW);
        return NEW;
    END;
    $function$
