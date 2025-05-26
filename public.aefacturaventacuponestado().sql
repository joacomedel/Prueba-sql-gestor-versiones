CREATE OR REPLACE FUNCTION public.aefacturaventacuponestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventacuponestado(OLD);
        return OLD;
    END;
    $function$
