CREATE OR REPLACE FUNCTION public.insertarccrectramite(fila rectramite)
 RETURNS rectramite
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.rectramitecc:= current_timestamp;
    UPDATE sincro.rectramite SET barra= fila.barra, idrecepcion= fila.idrecepcion, nrodoc= fila.nrodoc, rectramitecc= fila.rectramitecc WHERE barra= fila.barra AND idrecepcion= fila.idrecepcion AND nrodoc= fila.nrodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.rectramite(barra, idrecepcion, nrodoc, rectramitecc) VALUES (fila.barra, fila.idrecepcion, fila.nrodoc, fila.rectramitecc);
    END IF;
    RETURN fila;
    END;
    $function$
