CREATE OR REPLACE FUNCTION public.amsolicitudauditoria_archivos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccsolicitudauditoria_archivos(NEW);
        return NEW;
    END;
    $function$
