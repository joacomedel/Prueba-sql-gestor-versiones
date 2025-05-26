CREATE OR REPLACE FUNCTION public.insertarccliquidadorfiscalzxml(fila liquidadorfiscalzxml)
 RETURNS liquidadorfiscalzxml
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.liquidadorfiscalzxmlcc:= current_timestamp;
    UPDATE sincro.liquidadorfiscalzxml SET idcentroliquidadorfiscalz= fila.idcentroliquidadorfiscalz, idimpresorfiscal= fila.idimpresorfiscal, idliquidadorfiscalz= fila.idliquidadorfiscalz, lfz_cancelado= fila.lfz_cancelado, lfz_comp_referencia= fila.lfz_comp_referencia, lfz_fec_fecha_hora= fila.lfz_fec_fecha_hora, lfz_fechajornada= fila.lfz_fechajornada, lfz_infocliente= fila.lfz_infocliente, lfz_infocomprob= fila.lfz_infocomprob, lfz_infoitem= fila.lfz_infoitem, lfz_infoitem_bonif= fila.lfz_infoitem_bonif, lfz_infoitem_importe= fila.lfz_infoitem_importe, lfz_infoitem_importe_bonif= fila.lfz_infoitem_importe_bonif, lfz_infoitem_importe_xcantidad= fila.lfz_infoitem_importe_xcantidad, lfz_infopago= fila.lfz_infopago, lfz_infopagoimporte= fila.lfz_infopagoimporte, lfz_nrojornada= fila.lfz_nrojornada, lfz_total= fila.lfz_total, lfzgenerado= fila.lfzgenerado, liquidadorfiscalzxmlcc= fila.liquidadorfiscalzxmlcc WHERE idcentroliquidadorfiscalz= fila.idcentroliquidadorfiscalz AND idliquidadorfiscalz= fila.idliquidadorfiscalz AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.liquidadorfiscalzxml(idcentroliquidadorfiscalz, idimpresorfiscal, idliquidadorfiscalz, lfz_cancelado, lfz_comp_referencia, lfz_fec_fecha_hora, lfz_fechajornada, lfz_infocliente, lfz_infocomprob, lfz_infoitem, lfz_infoitem_bonif, lfz_infoitem_importe, lfz_infoitem_importe_bonif, lfz_infoitem_importe_xcantidad, lfz_infopago, lfz_infopagoimporte, lfz_nrojornada, lfz_total, lfzgenerado, liquidadorfiscalzxmlcc) VALUES (fila.idcentroliquidadorfiscalz, fila.idimpresorfiscal, fila.idliquidadorfiscalz, fila.lfz_cancelado, fila.lfz_comp_referencia, fila.lfz_fec_fecha_hora, fila.lfz_fechajornada, fila.lfz_infocliente, fila.lfz_infocomprob, fila.lfz_infoitem, fila.lfz_infoitem_bonif, fila.lfz_infoitem_importe, fila.lfz_infoitem_importe_bonif, fila.lfz_infoitem_importe_xcantidad, fila.lfz_infopago, fila.lfz_infopagoimporte, fila.lfz_nrojornada, fila.lfz_total, fila.lfzgenerado, fila.liquidadorfiscalzxmlcc);
    END IF;
    RETURN fila;
    END;
    $function$
