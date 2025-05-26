CREATE OR REPLACE FUNCTION public.amfacturadebitoimputacionpendiente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfacturadebitoimputacionpendiente(NEW);
        return NEW;
    END;
    $function$
