CREATE OR REPLACE FUNCTION public.aecertpersonal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccertpersonal(OLD);
        return OLD;
    END;
    $function$
