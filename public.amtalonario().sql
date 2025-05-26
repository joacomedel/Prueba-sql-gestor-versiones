CREATE OR REPLACE FUNCTION public.amtalonario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctalonario(NEW);
        return NEW;
    END;
    $function$
