CREATE OR REPLACE FUNCTION public.eliminarcccuentacorrientedeudapagocompensacion(fila cuentacorrientedeudapagocompensacion)
 RETURNS cuentacorrientedeudapagocompensacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentacorrientedeudapagocompensacioncc:= current_timestamp;
    delete from sincro.cuentacorrientedeudapagocompensacion WHERE idcentropagooriginal= fila.idcentropagooriginal AND idcentrodeudagenerada= fila.idcentrodeudagenerada AND iddeudagenerada= fila.iddeudagenerada AND idpagogenerada= fila.idpagogenerada AND idcentrodeudaoriginal= fila.idcentrodeudaoriginal AND iddeudaoriginal= fila.iddeudaoriginal AND idpagooriginal= fila.idpagooriginal AND idcentropagogenerada= fila.idcentropagogenerada AND TRUE;
    RETURN fila;
    END;
    $function$
