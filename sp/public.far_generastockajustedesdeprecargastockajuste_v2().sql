CREATE OR REPLACE FUNCTION public.far_generastockajustedesdeprecargastockajuste_v2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    cstockajuste CURSOR FOR SELECT idarticulo,idcentroarticulo,sum(psaicantidadcontada) as psaicantidadcontada
			FROM far_precargastockajusteitem 
			WHERE nullvalue(idstockajuste)  and idcentroprecargastockajusteitem=centro()
			GROUP BY  idarticulo,idcentroarticulo ;
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
       SELECT INTO vobservacion concat ('Generado usando SIMOS. ',text_concatenar(concat(controlo,' (',cantarticulos,') ',' : ',to_char(fechalectura,'DD/MM/YY'))))  as psaidescripcion
 				   FROM (
					select DISTINCT login as controlo,count(*) as cantarticulos,max(psaiaifechaingreso)::date as fechalectura
				
					from far_precargastockajusteitem 
                                        JOIN usuario ON idusuario = psaiidusuario
					where nullvalue(idstockajuste)  and idcentroprecargastockajusteitem=centro()
                                              AND psaicantidadcontada >= 0 and not psaiborrado
					GROUP BY  psaiidusuario,login 
				) as t;


      /*  SELECT INTO vobservacion text_concatenar(psaidescripcion)  as psaidescripcion
				   FROM (
					select psaidescripcion
					from far_precargastockajusteitem 
					where nullvalue(idstockajuste) 
					GROUP BY  psaidescripcion 
				) as t;*/

	CREATE TEMP TABLE temp_far_stockajusteitem  (idstockajusteitem INTEGER,  idstockajuste bigint,  saiimporteunitario double precision, idsigno integer,  saicantidad integer,  saiimportetotal double precision,   saialicuotaiva double precision,  saiimporteiva double precision,  saifechaingreso date ,  idusuario integer,  idarticulo integer,  saifechavencimiento date,  idcentrostockajuste integer ,  idcentrostockajusteitem integer ,  idcentroarticulo integer,  saicantidadactual integer,  saanulado boolean,  safecha timestamp,  sadescripcion character varying,  saesautomatico boolean ,  idstockajusteestadotipo integer,   operacion character varying );


	INSERT INTO temp_far_stockajusteitem (idusuario,idarticulo,idcentroarticulo,sadescripcion,saicantidadactual,saicantidad,idsigno) 
	(
	SELECT 
	rusuario.idusuario
        ,idarticulo,idcentroarticulo
        ,vobservacion as sadescripcion
        ,CASE WHEN nullvalue(psaistocksistema) THEN  far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) 
			ELSE psaistocksistema END as stockactual
	,abs(psaicantidadcontada - 
               CASE WHEN nullvalue(psaistocksistema) THEN  far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) 
			ELSE psaistocksistema END         

          ) as saicantidad
	,case when psaicantidadcontada - 
			(CASE WHEN nullvalue(psaistocksistema) THEN far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) 
			ELSE psaistocksistema  END) < 0
			then -1 else 1 end as idsigno
	FROM (
--KR, ML 22-01-18 Nos quedamos solo con el min porque solo es posible realizar ventas mientras se esta controlando el stock, recibir un pedido podria dar error. 
		select idarticulo,idcentroarticulo,sum(psaicantidadcontada) as psaicantidadcontada, min(psaistocksistema) as psaistocksistema
		from far_precargastockajusteitem 
		where nullvalue(idstockajuste)  and idcentroprecargastockajusteitem=centro()
                      AND psaicantidadcontada >= 0 and not psaiborrado
		GROUP BY  idarticulo,idcentroarticulo 
		) as t
	);

	
   SELECT INTO respuesta * FROM far_stockajustedesdetemporal_2();
   vidstockajuste = split_part(respuesta, '-',1) ::bigint;
   vidcentrostockajuste = split_part(respuesta, '-',2)::integer;
   UPDATE far_precargastockajusteitem SET idstockajuste	 = vidstockajuste
                                          ,idcentrostockajuste = vidcentrostockajuste
          WHERE  nullvalue(idstockajuste) and idcentroprecargastockajusteitem=centro()
                 AND psaicantidadcontada  >= 0 and not psaiborrado;
  
--MaLaPi 09-11-2017 Genero los Informes 
      SELECT INTO resp * FROM far_generastockajustedesdeprecargastockajuste_informes(vidstockajuste,vidcentrostockajuste);
   return respuesta;

END;$function$
