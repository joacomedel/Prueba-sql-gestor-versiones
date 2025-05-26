CREATE OR REPLACE FUNCTION public.aedeclarasubs()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdeclarasubs(OLD);
        return OLD;
    END;
    $function$
