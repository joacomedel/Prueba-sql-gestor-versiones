CREATE OR REPLACE FUNCTION public.insertarccinfaporrecibido(fila infaporrecibido)
 RETURNS infaporrecibido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infaporrecibidocc:= current_timestamp;
    UPDATE sincro.infaporrecibido SET barra= fila.barra, fechmodificacion= fila.fechmodificacion, idlaboral= fila.idlaboral, infaporrecibidocc= fila.infaporrecibidocc, nrodoc= fila.nrodoc, nroliquidacion= fila.nroliquidacion, nrotipoinforme= fila.nrotipoinforme, tipoinforme= fila.tipoinforme WHERE fechmodificacion= fila.fechmodificacion AND idlaboral= fila.idlaboral AND nrodoc= fila.nrodoc AND nroliquidacion= fila.nroliquidacion AND nrotipoinforme= fila.nrotipoinforme AND tipoinforme= fila.tipoinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.infaporrecibido(barra, fechmodificacion, idlaboral, infaporrecibidocc, nrodoc, nroliquidacion, nrotipoinforme, tipoinforme) VALUES (fila.barra, fila.fechmodificacion, fila.idlaboral, fila.infaporrecibidocc, fila.nrodoc, fila.nroliquidacion, fila.nrotipoinforme, fila.tipoinforme);
    END IF;
    RETURN fila;
    END;
    $function$
