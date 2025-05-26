CREATE OR REPLACE FUNCTION public.ambenefreci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccbenefreci(NEW);
        return NEW;
    END;
    $function$
