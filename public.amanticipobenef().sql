CREATE OR REPLACE FUNCTION public.amanticipobenef()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccanticipobenef(NEW);
        return NEW;
    END;
    $function$
