CREATE OR REPLACE FUNCTION public.far_generastockajuste_cierreinventario()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    
    rstockajuste record;
    respuesta varchar;
    rusuario record;
    rexiste RECORD;
    rtemp record;
    resp varchar;
    vobservacion text;
    vidstockajuste bigint;
    vidcentrostockajuste integer;
BEGIN
	CREATE TABLE temp_comprobanteajuste_generados (idstockajuste bigint,idcentrostockajuste integer,obs varchar,fechacreacion timestamp default CURRENT_TIMESTAMP);
        --Cargo todos los comprobantes de ajuste que se generaron el dia del cierre y que no se anularon o cancelaron
        INSERT INTO temp_comprobanteajuste_generados(idstockajuste,idcentrostockajuste,obs) 
         (
	SELECT idstockajuste,idcentrostockajuste,'Generados por Usuario' 
		FROM far_stockajuste 
		NATURAL JOIN far_stockajusteestado
		where safecha >= current_Date 
		AND NOT saesautomatico
			AND nullvalue(eaefechafin)
			AND (idstockajusteestadotipo <> 5 
			OR idstockajusteestadotipo <> 4 )
			);
	--Genera el Comprobante de Ajuste de la precarga
	SELECT INTO respuesta * FROM far_generastockajustedesdeprecargastockajuste_v2(); --> llama al que genera el informe.
        vidstockajuste = split_part(respuesta, '-',1) ::bigint;
	vidcentrostockajuste = split_part(respuesta, '-',2)::integer;
	--Inserto el comprobante de Ajusto de la Precarga
	INSERT INTO temp_comprobanteajuste_generados(idstockajuste,idcentrostockajuste,obs) VALUES(vidstockajuste,vidcentrostockajuste,'Precarga'); 
	--Genera el Comprobante de Ajuste de los articulos picados y que luego quedaron en negativo
	DROP TABLE temp_far_stockajusteitem;
        SELECT INTO respuesta * FROM far_generastockajustedesdeprecargastockajuste_negativos(); 
        vidstockajuste = split_part(respuesta, '-',1) ::bigint;
	vidcentrostockajuste = split_part(respuesta, '-',2)::integer; 
        --Inserto el comprobante de Ajusto de los negativos
	INSERT INTO temp_comprobanteajuste_generados(idstockajuste,idcentrostockajuste,obs) VALUES(vidstockajuste,vidcentrostockajuste,'Negativos');  

	--SELECT * FROM temp_comprobanteajuste
	--Genero el comprobante de ajuste de todos los articulos activos que no se picaron, el stock queda en cero
	DROP TABLE temp_far_stockajusteitem;
	SELECT INTO respuesta * FROM far_generastockajustecomplemento();
        vidstockajuste = split_part(respuesta, '-',1) ::bigint;
	vidcentrostockajuste = split_part(respuesta, '-',2)::integer; 
        --Inserto el comprobante de Ajusto de los negativos
	INSERT INTO temp_comprobanteajuste_generados(idstockajuste,idcentrostockajuste,obs) VALUES(vidstockajuste,vidcentrostockajuste,'Complemento');  

   return respuesta;

END;
$function$
