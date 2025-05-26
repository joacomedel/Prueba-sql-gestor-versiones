CREATE OR REPLACE FUNCTION public.eliminarccdiscpersonaborradas(fila discpersonaborradas)
 RETURNS discpersonaborradas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.discpersonaborradascc:= current_timestamp;
    delete from sincro.discpersonaborradas WHERE fechavtodisc= fila.fechavtodisc AND iddisc= fila.iddisc AND iddiscpersonaborradas= fila.iddiscpersonaborradas AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
