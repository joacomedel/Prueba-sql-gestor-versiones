CREATE OR REPLACE FUNCTION public.eliminarcclaboratorio(fila laboratorio)
 RETURNS laboratorio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.laboratoriocc:= current_timestamp;
    delete from sincro.laboratorio WHERE idlaboratorio= fila.idlaboratorio AND TRUE;
    RETURN fila;
    END;
    $function$
