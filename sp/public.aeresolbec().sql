CREATE OR REPLACE FUNCTION public.aeresolbec()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccresolbec(OLD);
        return OLD;
    END;
    $function$
