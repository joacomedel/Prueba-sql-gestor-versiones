CREATE OR REPLACE FUNCTION public.amfacturaaporte()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaaporte(NEW);
        return NEW;
    END;
    $function$
