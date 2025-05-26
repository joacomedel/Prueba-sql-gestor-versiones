CREATE OR REPLACE FUNCTION public.eliminarccliquidadorfiscalzxml(fila liquidadorfiscalzxml)
 RETURNS liquidadorfiscalzxml
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.liquidadorfiscalzxmlcc:= current_timestamp;
    delete from sincro.liquidadorfiscalzxml WHERE idcentroliquidadorfiscalz= fila.idcentroliquidadorfiscalz AND idliquidadorfiscalz= fila.idliquidadorfiscalz AND TRUE;
    RETURN fila;
    END;
    $function$
