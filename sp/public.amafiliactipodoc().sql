CREATE OR REPLACE FUNCTION public.amafiliactipodoc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafiliactipodoc(NEW);
        return NEW;
    END;
    $function$
