CREATE OR REPLACE FUNCTION public.aepagoscuentacorriente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpagoscuentacorriente(OLD);
        return OLD;
    END;
    $function$
