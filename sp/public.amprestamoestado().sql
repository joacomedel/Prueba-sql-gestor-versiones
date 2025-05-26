CREATE OR REPLACE FUNCTION public.amprestamoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprestamoestado(NEW);
        return NEW;
    END;
    $function$
