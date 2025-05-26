CREATE OR REPLACE FUNCTION public.aefacturacionfechas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturacionfechas(OLD);
        return OLD;
    END;
    $function$
