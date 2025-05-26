CREATE OR REPLACE FUNCTION public.aerectramite()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrectramite(OLD);
        return OLD;
    END;
    $function$
