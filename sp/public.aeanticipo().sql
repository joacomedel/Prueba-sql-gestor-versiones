CREATE OR REPLACE FUNCTION public.aeanticipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccanticipo(OLD);
        return OLD;
    END;
    $function$
