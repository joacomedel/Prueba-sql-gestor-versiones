CREATE OR REPLACE FUNCTION public.amdatosauditoriafacturafarmacia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdatosauditoriafacturafarmacia(NEW);
        return NEW;
    END;
    $function$
