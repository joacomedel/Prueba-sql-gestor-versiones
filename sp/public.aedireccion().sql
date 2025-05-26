CREATE OR REPLACE FUNCTION public.aedireccion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdireccion(OLD);
        return OLD;
    END;
    $function$
