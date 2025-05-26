CREATE OR REPLACE FUNCTION public.far_generastockajustecomplemento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
   -- Temporal que contiene los comprobantes de ajuste de los que se quiere generar su complemento
    cstockajuste CURSOR FOR SELECT * FROM temp_comprobanteajuste_generados ;


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

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN
		rusuario.idusuario = 25;
	END IF;
    /* OBSERVACION CORRESPONDIENTE A LA CABECERA DEL COMP AJUSTE*/
       
       SELECT INTO  vobservacion concat('Comprobante de Ajuste de articulos activos que no se encontraron en: ', text_concatenar(concat(' // ',idstockajuste,'-',idcentrostockajuste,' // ' )))
       FROM temp_comprobanteajuste_generados
       NATURAL JOIN far_stockajusteestado
       WHERE nullvalue(eaefechafin) AND (idstockajusteestadotipo <> 3)  ;


	CREATE TEMP TABLE temp_far_stockajusteitem  (idstockajusteitem INTEGER,  idstockajuste bigint,  saiimporteunitario double precision, idsigno integer,  saicantidad integer,  saiimportetotal double precision,   saialicuotaiva double precision,  saiimporteiva double precision,  saifechaingreso date ,  idusuario integer,  idarticulo integer,  saifechavencimiento date,  idcentrostockajuste integer ,  idcentrostockajusteitem integer ,  idcentroarticulo integer,  saicantidadactual integer,  saanulado boolean,  safecha timestamp,  sadescripcion character varying,  saesautomatico boolean ,  idstockajusteestadotipo integer,   operacion character varying );

    /* BUSCO LOS ITEM DEL COMPROBANTE DE AJUSTE QUE SE CORRESPONDEN A TODOS LOS ARTICULOS ACTIVOS QUE NO SE ENCUENTRA EN EL COMPROBANTE DE AJUSTE $1-$2*/
	INSERT INTO temp_far_stockajusteitem (idusuario,idarticulo,idcentroarticulo,sadescripcion,saicantidadactual,saicantidad,idsigno)(
 	       SELECT 	rusuario.idusuario  ,idarticulo,idcentroarticulo
                   ,vobservacion as sadescripcion	,far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) as stockactual
	                ,abs(psaicantidadcontada - far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo)) as saicantidad
	               ,case when psaicantidadcontada - far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) < 0 then -1 else 1 end as idsigno
	FROM (
		SELECT distinct idarticulo,idcentroarticulo,0 as psaicantidadcontada
        FROM far_articulo
        LEFT JOIN (SELECT * FROM temp_comprobanteajuste_generados 
                            NATURAL JOIN far_stockajuste 
                            NATURAL JOIN far_stockajusteestado
		            NATURAL JOIN far_stockajusteitem 
--MaLaPi 03/01/2023 Solo tomo los comprobantes de stock NO cancelados
                            WHERE nullvalue(eaefechafin) AND (idstockajusteestadotipo <> 3) 
) as t USING(idcentroarticulo,idarticulo)
        WHERE true --aactivo   -- articulo activo MaLaPi 27-07-2021 Lo comento pues el reporte de stock de articulo, muestra todos los articulos no solo los activos
              and far_darcantidadarticulostock(idarticulo,idcentroarticulo) <> 0  -- stock actual <> 0
              and nullvalue(idstockajuste) -- no se encuentra en el comprobante de ajuste enviado por parametro
		) as t
	);

	
   SELECT INTO respuesta * FROM far_stockajustedesdetemporal_2();
   return respuesta;

END;
$function$
