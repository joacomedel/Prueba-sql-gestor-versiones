CREATE OR REPLACE FUNCTION public.aecambioestadosorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccambioestadosorden(OLD);
        return OLD;
    END;
    $function$
