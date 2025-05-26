CREATE OR REPLACE FUNCTION public.aefacturadebitoimputacionpendiente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturadebitoimputacionpendiente(OLD);
        return OLD;
    END;
    $function$
