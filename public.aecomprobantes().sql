CREATE OR REPLACE FUNCTION public.aecomprobantes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccomprobantes(OLD);
        return OLD;
    END;
    $function$
