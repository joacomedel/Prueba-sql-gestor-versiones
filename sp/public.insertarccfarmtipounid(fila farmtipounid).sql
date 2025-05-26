CREATE OR REPLACE FUNCTION public.insertarccfarmtipounid(fila farmtipounid)
 RETURNS farmtipounid
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.farmtipounidcc:= current_timestamp;
    UPDATE sincro.farmtipounid SET farmtipounidcc= fila.farmtipounidcc, ftudescripcion= fila.ftudescripcion, idfarmtipounid= fila.idfarmtipounid WHERE idfarmtipounid= fila.idfarmtipounid AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.farmtipounid(farmtipounidcc, ftudescripcion, idfarmtipounid) VALUES (fila.farmtipounidcc, fila.ftudescripcion, fila.idfarmtipounid);
    END IF;
    RETURN fila;
    END;
    $function$
