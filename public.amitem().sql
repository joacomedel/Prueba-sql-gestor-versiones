CREATE OR REPLACE FUNCTION public.amitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccitem(NEW);
        return NEW;
    END;
    $function$
