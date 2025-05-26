CREATE OR REPLACE FUNCTION public.aerecibocobroacuenta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecibocobroacuenta(OLD);
        return OLD;
    END;
    $function$
