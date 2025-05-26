CREATE OR REPLACE FUNCTION public.eliminarccfarmtipounid(fila farmtipounid)
 RETURNS farmtipounid
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.farmtipounidcc:= current_timestamp;
    delete from sincro.farmtipounid WHERE idfarmtipounid= fila.idfarmtipounid AND TRUE;
    RETURN fila;
    END;
    $function$
