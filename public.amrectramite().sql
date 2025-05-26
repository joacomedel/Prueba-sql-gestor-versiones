CREATE OR REPLACE FUNCTION public.amrectramite()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrectramite(NEW);
        return NEW;
    END;
    $function$
