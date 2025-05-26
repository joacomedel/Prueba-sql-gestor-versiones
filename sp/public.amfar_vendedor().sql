CREATE OR REPLACE FUNCTION public.amfar_vendedor()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_vendedor(NEW);
        return NEW;
    END;
    $function$
