CREATE OR REPLACE FUNCTION public.ambeneficiariosborrados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccbeneficiariosborrados(NEW);
        return NEW;
    END;
    $function$
