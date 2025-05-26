CREATE OR REPLACE FUNCTION public.amdiscpersonaborradas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdiscpersonaborradas(NEW);
        return NEW;
    END;
    $function$
