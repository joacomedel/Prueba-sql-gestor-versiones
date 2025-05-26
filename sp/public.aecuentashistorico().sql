CREATE OR REPLACE FUNCTION public.aecuentashistorico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentashistorico(OLD);
        return OLD;
    END;
    $function$
