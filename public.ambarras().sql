CREATE OR REPLACE FUNCTION public.ambarras()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccbarras(NEW);
        return NEW;
    END;
    $function$
