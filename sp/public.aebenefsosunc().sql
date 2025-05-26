CREATE OR REPLACE FUNCTION public.aebenefsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccbenefsosunc(OLD);
        return OLD;
    END;
    $function$
