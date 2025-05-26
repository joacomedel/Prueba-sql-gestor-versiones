CREATE OR REPLACE FUNCTION public.amresolbec()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccresolbec(NEW);
        return NEW;
    END;
    $function$
