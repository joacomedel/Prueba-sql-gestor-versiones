CREATE OR REPLACE FUNCTION public.aereintegroestudio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccreintegroestudio(OLD);
        return OLD;
    END;
    $function$
