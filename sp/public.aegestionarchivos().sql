CREATE OR REPLACE FUNCTION public.aegestionarchivos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccgestionarchivos(OLD);
        return OLD;
    END;
    $function$
