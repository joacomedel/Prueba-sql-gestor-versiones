CREATE OR REPLACE FUNCTION public.amadmusuariostransaccion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccadmusuariostransaccion(NEW);
        return NEW;
    END;
    $function$
