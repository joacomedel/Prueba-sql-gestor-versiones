CREATE OR REPLACE FUNCTION public.amgestionarchivos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccgestionarchivos(NEW);
        return NEW;
    END;
    $function$
