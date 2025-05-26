CREATE OR REPLACE FUNCTION public.amfar_movimientostockitemremito()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostockitemremito(NEW);
        return NEW;
    END;
    $function$
