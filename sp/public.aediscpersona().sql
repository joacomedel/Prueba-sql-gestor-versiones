CREATE OR REPLACE FUNCTION public.aediscpersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdiscpersona(OLD);
        return OLD;
    END;
    $function$
