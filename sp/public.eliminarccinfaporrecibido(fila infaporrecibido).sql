CREATE OR REPLACE FUNCTION public.eliminarccinfaporrecibido(fila infaporrecibido)
 RETURNS infaporrecibido
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infaporrecibidocc:= current_timestamp;
    delete from sincro.infaporrecibido WHERE fechmodificacion= fila.fechmodificacion AND idlaboral= fila.idlaboral AND nrodoc= fila.nrodoc AND nroliquidacion= fila.nroliquidacion AND nrotipoinforme= fila.nrotipoinforme AND tipoinforme= fila.tipoinforme AND TRUE;
    RETURN fila;
    END;
    $function$
