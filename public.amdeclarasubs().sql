CREATE OR REPLACE FUNCTION public.amdeclarasubs()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdeclarasubs(NEW);
        return NEW;
    END;
    $function$
