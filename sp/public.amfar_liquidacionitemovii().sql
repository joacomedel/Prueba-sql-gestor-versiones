CREATE OR REPLACE FUNCTION public.amfar_liquidacionitemovii()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_liquidacionitemovii(NEW);
        return NEW;
    END;
    $function$
