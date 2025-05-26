CREATE OR REPLACE FUNCTION public.ambeneficiariosreciborrados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccbeneficiariosreciborrados(NEW);
        return NEW;
    END;
    $function$
