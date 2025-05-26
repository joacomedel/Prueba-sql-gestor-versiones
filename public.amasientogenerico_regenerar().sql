CREATE OR REPLACE FUNCTION public.amasientogenerico_regenerar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccasientogenerico_regenerar(NEW);
        return NEW;
    END;
    $function$
