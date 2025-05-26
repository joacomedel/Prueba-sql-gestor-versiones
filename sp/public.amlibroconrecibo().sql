CREATE OR REPLACE FUNCTION public.amlibroconrecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcclibroconrecibo(NEW);
        return NEW;
    END;
    $function$
