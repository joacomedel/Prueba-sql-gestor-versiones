CREATE OR REPLACE FUNCTION public.ampresupuestoitemordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpresupuestoitemordenpago(NEW);
        return NEW;
    END;
    $function$
