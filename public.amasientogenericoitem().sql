CREATE OR REPLACE FUNCTION public.amasientogenericoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccasientogenericoitem(NEW);
        return NEW;
    END;
    $function$
