CREATE OR REPLACE FUNCTION public.aediscpersonaborradas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdiscpersonaborradas(OLD);
        return OLD;
    END;
    $function$
