CREATE OR REPLACE FUNCTION public.ampagoscuentacorriente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpagoscuentacorriente(NEW);
        return NEW;
    END;
    $function$
