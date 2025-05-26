CREATE OR REPLACE FUNCTION public.amfar_movimientostockitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostockitem(NEW);
        return NEW;
    END;
    $function$
