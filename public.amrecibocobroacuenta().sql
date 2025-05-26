CREATE OR REPLACE FUNCTION public.amrecibocobroacuenta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecibocobroacuenta(NEW);
        return NEW;
    END;
    $function$
