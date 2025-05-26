CREATE OR REPLACE FUNCTION public.aecompramedicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccompramedicamento(OLD);
        return OLD;
    END;
    $function$
