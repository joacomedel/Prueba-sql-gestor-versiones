CREATE OR REPLACE FUNCTION public.amasientocontable()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccasientocontable(NEW);
        return NEW;
    END;
    $function$
