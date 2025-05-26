CREATE OR REPLACE FUNCTION public.aematricula()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmatricula(OLD);
        return OLD;
    END;
    $function$
