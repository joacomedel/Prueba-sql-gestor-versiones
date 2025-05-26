CREATE OR REPLACE FUNCTION public.eliminarccgestionarchivos(fila gestionarchivos)
 RETURNS gestionarchivos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.gestionarchivoscc:= current_timestamp;
    delete from sincro.gestionarchivos WHERE idgestionarchivos= fila.idgestionarchivos AND idcentrogestionarchivos= fila.idcentrogestionarchivos AND TRUE;
    RETURN fila;
    END;
    $function$
