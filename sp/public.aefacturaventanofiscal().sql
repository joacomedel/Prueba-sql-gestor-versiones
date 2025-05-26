CREATE OR REPLACE FUNCTION public.aefacturaventanofiscal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfacturaventanofiscal(OLD);
        return OLD;
    END;
    $function$
