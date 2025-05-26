CREATE OR REPLACE FUNCTION public.aepersonajuridicabis()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpersonajuridicabis(OLD);
        return OLD;
    END;
    $function$
