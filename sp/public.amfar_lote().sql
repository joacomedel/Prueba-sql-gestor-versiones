CREATE OR REPLACE FUNCTION public.amfar_lote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_lote(NEW);
        return NEW;
    END;
    $function$
