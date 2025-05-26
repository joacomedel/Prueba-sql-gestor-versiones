CREATE OR REPLACE FUNCTION public.ambenefsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccbenefsosunc(NEW);
        return NEW;
    END;
    $function$
