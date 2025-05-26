CREATE OR REPLACE FUNCTION public.amdiscpersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdiscpersona(NEW);
        return NEW;
    END;
    $function$
