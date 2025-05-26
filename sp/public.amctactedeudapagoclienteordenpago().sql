CREATE OR REPLACE FUNCTION public.amctactedeudapagoclienteordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctactedeudapagoclienteordenpago(NEW);
        return NEW;
    END;
    $function$
