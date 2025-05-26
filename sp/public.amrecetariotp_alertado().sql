CREATE OR REPLACE FUNCTION public.amrecetariotp_alertado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetariotp_alertado(NEW);
        return NEW;
    END;
    $function$
