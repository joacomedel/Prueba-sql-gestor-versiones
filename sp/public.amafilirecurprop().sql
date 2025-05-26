CREATE OR REPLACE FUNCTION public.amafilirecurprop()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilirecurprop(NEW);
        return NEW;
    END;
    $function$
