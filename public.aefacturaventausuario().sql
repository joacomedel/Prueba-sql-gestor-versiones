CREATE OR REPLACE FUNCTION public.aefacturaventausuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventausuario(OLD);
        return OLD;
    END;
    $function$
