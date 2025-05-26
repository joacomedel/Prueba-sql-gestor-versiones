CREATE OR REPLACE FUNCTION public.amcuentashistorico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentashistorico(NEW);
        return NEW;
    END;
    $function$
