CREATE OR REPLACE FUNCTION public.aepersonajuridica()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpersonajuridica(OLD);
        return OLD;
    END;
    $function$
