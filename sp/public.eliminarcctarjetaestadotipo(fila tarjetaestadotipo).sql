CREATE OR REPLACE FUNCTION public.eliminarcctarjetaestadotipo(fila tarjetaestadotipo)
 RETURNS tarjetaestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tarjetaestadotipocc:= current_timestamp;
    delete from sincro.tarjetaestadotipo WHERE idestadotipo= fila.idestadotipo AND TRUE;
    RETURN fila;
    END;
    $function$
