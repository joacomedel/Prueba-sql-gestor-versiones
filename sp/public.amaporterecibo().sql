CREATE OR REPLACE FUNCTION public.amaporterecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaporterecibo(NEW);
        return NEW;
    END;
    $function$
