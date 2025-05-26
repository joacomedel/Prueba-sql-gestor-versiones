CREATE OR REPLACE FUNCTION public.eliminarcchistobarras(fila histobarras)
 RETURNS histobarras
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.histobarrascc:= current_timestamp;
    delete from sincro.histobarras WHERE barra= fila.barra AND fechaini= fila.fechaini AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
