CREATE OR REPLACE FUNCTION public.amconsumoturismo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconsumoturismo(NEW);
        return NEW;
    END;
    $function$
