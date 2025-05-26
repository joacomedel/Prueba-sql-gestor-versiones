CREATE OR REPLACE FUNCTION public.amreintegrorecetario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreintegrorecetario(NEW);
        return NEW;
    END;
    $function$
