CREATE OR REPLACE FUNCTION public.aecuponestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuponestado(OLD);
        return OLD;
    END;
    $function$
