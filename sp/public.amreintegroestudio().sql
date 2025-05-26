CREATE OR REPLACE FUNCTION public.amreintegroestudio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreintegroestudio(NEW);
        return NEW;
    END;
    $function$
