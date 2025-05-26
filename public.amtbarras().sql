CREATE OR REPLACE FUNCTION public.amtbarras()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctbarras(NEW);
        return NEW;
    END;
    $function$
