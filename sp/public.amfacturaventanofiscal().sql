CREATE OR REPLACE FUNCTION public.amfacturaventanofiscal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventanofiscal(NEW);
        return NEW;
    END;
    $function$
