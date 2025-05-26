CREATE OR REPLACE FUNCTION public.amreintegrobenef()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreintegrobenef(NEW);
        return NEW;
    END;
    $function$
