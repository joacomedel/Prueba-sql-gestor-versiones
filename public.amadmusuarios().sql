CREATE OR REPLACE FUNCTION public.amadmusuarios()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccadmusuarios(NEW);
        return NEW;
    END;
    $function$
