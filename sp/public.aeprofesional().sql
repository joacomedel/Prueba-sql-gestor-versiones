CREATE OR REPLACE FUNCTION public.aeprofesional()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprofesional(OLD);
        return OLD;
    END;
    $function$
