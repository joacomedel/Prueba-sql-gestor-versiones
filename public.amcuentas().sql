CREATE OR REPLACE FUNCTION public.amcuentas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentas(NEW);
        return NEW;
    END;
    $function$
