CREATE OR REPLACE FUNCTION public.aetalonario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctalonario(OLD);
        return OLD;
    END;
    $function$
