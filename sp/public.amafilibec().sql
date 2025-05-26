CREATE OR REPLACE FUNCTION public.amafilibec()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilibec(NEW);
        return NEW;
    END;
    $function$
