CREATE OR REPLACE FUNCTION public.amfacturaventacuponestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventacuponestado(NEW);
        return NEW;
    END;
    $function$
