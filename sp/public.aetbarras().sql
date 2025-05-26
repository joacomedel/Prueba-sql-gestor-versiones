CREATE OR REPLACE FUNCTION public.aetbarras()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctbarras(OLD);
        return OLD;
    END;
    $function$
