CREATE OR REPLACE FUNCTION public.eliminarccdiscpersona(fila discpersona)
 RETURNS discpersona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.discpersonacc:= current_timestamp;
    delete from sincro.discpersona WHERE iddisc= fila.iddisc AND fechavtodisc= fila.fechavtodisc AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
