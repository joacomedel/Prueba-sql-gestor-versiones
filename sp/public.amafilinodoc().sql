CREATE OR REPLACE FUNCTION public.amafilinodoc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccafilinodoc(NEW);
        return NEW;
    END;
    $function$
