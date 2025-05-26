CREATE OR REPLACE FUNCTION public.aelaboratorio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcclaboratorio(OLD);
        return OLD;
    END;
    $function$
