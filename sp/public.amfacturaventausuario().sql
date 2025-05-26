CREATE OR REPLACE FUNCTION public.amfacturaventausuario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturaventausuario(NEW);
        return NEW;
    END;
    $function$
