CREATE OR REPLACE FUNCTION public.eliminarcccuponestado(fila cuponestado)
 RETURNS cuponestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuponestadocc:= current_timestamp;
    delete from sincro.cuponestado WHERE idcentrocupon= fila.idcentrocupon AND idcentrocuponestado= fila.idcentrocuponestado AND idcetcambioestado= fila.idcetcambioestado AND idcupon= fila.idcupon AND TRUE;
    RETURN fila;
    END;
    $function$
