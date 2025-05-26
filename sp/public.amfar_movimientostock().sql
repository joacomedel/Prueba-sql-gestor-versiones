CREATE OR REPLACE FUNCTION public.amfar_movimientostock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostock(NEW);
        return NEW;
    END;
    $function$
