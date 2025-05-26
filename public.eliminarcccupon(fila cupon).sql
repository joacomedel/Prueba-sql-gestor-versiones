CREATE OR REPLACE FUNCTION public.eliminarcccupon(fila cupon)
 RETURNS cupon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuponcc:= current_timestamp;
    delete from sincro.cupon WHERE idcentrocupon= fila.idcentrocupon AND idcupon= fila.idcupon AND TRUE;
    RETURN fila;
    END;
    $function$
