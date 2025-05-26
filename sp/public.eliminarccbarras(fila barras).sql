CREATE OR REPLACE FUNCTION public.eliminarccbarras(fila barras)
 RETURNS barras
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.barrascc:= current_timestamp;
    delete from sincro.barras WHERE barra= fila.barra AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
