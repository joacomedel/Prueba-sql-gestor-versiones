CREATE OR REPLACE FUNCTION public.amfacturacionfechas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturacionfechas(NEW);
        return NEW;
    END;
    $function$
