CREATE OR REPLACE FUNCTION public.amfar_liquidacionitemfvc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_liquidacionitemfvc(NEW);
        return NEW;
    END;
    $function$
