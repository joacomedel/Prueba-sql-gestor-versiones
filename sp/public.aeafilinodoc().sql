CREATE OR REPLACE FUNCTION public.aeafilinodoc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccafilinodoc(OLD);
        return OLD;
    END;
    $function$
