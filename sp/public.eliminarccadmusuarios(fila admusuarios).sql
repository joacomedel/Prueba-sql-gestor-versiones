CREATE OR REPLACE FUNCTION public.eliminarccadmusuarios(fila admusuarios)
 RETURNS admusuarios
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admusuarioscc:= current_timestamp;
    delete from sincro.admusuarios WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
