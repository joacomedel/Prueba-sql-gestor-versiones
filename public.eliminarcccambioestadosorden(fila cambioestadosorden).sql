CREATE OR REPLACE FUNCTION public.eliminarcccambioestadosorden(fila cambioestadosorden)
 RETURNS cambioestadosorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cambioestadosordencc:= current_timestamp;
    delete from sincro.cambioestadosorden WHERE idcambioestadosorden= fila.idcambioestadosorden AND idcentrocambioestadosorden= fila.idcentrocambioestadosorden AND TRUE;
    RETURN fila;
    END;
    $function$
