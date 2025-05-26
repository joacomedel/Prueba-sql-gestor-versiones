CREATE OR REPLACE FUNCTION public.amconsumo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconsumo(NEW);
        return NEW;
    END;
    $function$
