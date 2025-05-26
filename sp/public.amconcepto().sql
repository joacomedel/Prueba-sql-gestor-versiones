CREATE OR REPLACE FUNCTION public.amconcepto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconcepto(NEW);
        return NEW;
    END;
    $function$
