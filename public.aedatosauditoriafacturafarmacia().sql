CREATE OR REPLACE FUNCTION public.aedatosauditoriafacturafarmacia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdatosauditoriafacturafarmacia(OLD);
        return OLD;
    END;
    $function$
