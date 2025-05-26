CREATE OR REPLACE FUNCTION public.eliminarccrectramite(fila rectramite)
 RETURNS rectramite
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.rectramitecc:= current_timestamp;
    delete from sincro.rectramite WHERE barra= fila.barra AND idrecepcion= fila.idrecepcion AND nrodoc= fila.nrodoc AND TRUE;
    RETURN fila;
    END;
    $function$
