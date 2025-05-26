CREATE OR REPLACE FUNCTION public.amimportesrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccimportesrecibo(NEW);
        return NEW;
    END;
    $function$
