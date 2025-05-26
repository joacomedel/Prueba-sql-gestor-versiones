CREATE OR REPLACE FUNCTION public.amsolicitudauditoria()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccsolicitudauditoria(NEW);
        return NEW;
    END;
    $function$
