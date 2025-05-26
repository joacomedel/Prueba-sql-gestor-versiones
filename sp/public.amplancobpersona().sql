CREATE OR REPLACE FUNCTION public.amplancobpersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccplancobpersona(NEW);
        return NEW;
    END;
    $function$
