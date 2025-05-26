CREATE OR REPLACE FUNCTION public.amasientogenerico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccasientogenerico(NEW);
        return NEW;
    END;
    $function$
