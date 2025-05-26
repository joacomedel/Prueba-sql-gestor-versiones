CREATE OR REPLACE FUNCTION public.far_generastockajustedesdeprecargastockajuste_negativos()
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

	SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	IF NOT FOUND THEN 
		rusuario.idusuario = 25;
	END IF;
       SELECT INTO vobservacion concat ('Generado usando SIMOS - Casos para verificar. ',text_concatenar(concat(controlo,' (',cantarticulos,') ',' : ',to_char(fechalectura,'DD/MM/YY'))))  as psaidescripcion
 				   FROM (
					select DISTINCT login as controlo,count(*) as cantarticulos,max(fechalectura) as fechalectura
				
					from (SELECT far_precargastockajusteitem.psaiidusuario,far_precargastockajusteitem.idarticulo,far_precargastockajusteitem.idcentroarticulo,sum(psaicantidadcontada) as psaicantidadcontada,max(psaiaifechaingreso)::date as fechalectura
						from far_precargastockajusteitem 
						NATURAL JOIN far_articulo as fa
						LEFT JOIN far_articulo as fap ON fa.idarticulo = fap.idarticulopadre AND fa.idcentroarticulo = fap.idcentroarticulopadre
						LEFT JOIN (SELECT idarticulo,idcentroarticulo,idstockajuste,idcentrostockajuste 
							FROM far_stockajusteitem
							NATURAL JOIN temp_comprobanteajuste_generados
							WHERE obs = 'Precarga'
						 ) as sa ON fa.idarticulo = sa.idarticulo AND fa.idcentroarticulo = sa.idcentroarticulo
							Where nullvalue(far_precargastockajusteitem.idstockajuste) 
							AND far_precargastockajusteitem.psaicantidadcontada<0
							AND nullvalue(sa.idstockajuste) --son los articulos que ya generaron movimiento de stock en la precarga
							AND far_darcantidadarticulostock(fa.idarticulo,fa.idcentroarticulo) <> 0 -- Si el stock es cero, quiere decir que no se usa 
							AND nullvalue(fap.idarticulo) --son los padres de los fraccionados 
							AND fa.aactivo --son los que se desactivaron durante la lectura
							and not psaiborrado --No estan marcados como borrados
							GROUP BY far_precargastockajusteitem.psaiidusuario,far_precargastockajusteitem.idarticulo,far_precargastockajusteitem.idcentroarticulo 
) as tt 
                                        JOIN usuario ON idusuario = psaiidusuario
					GROUP BY  psaiidusuario,login 
				) as t;


     
	CREATE TEMP TABLE temp_far_stockajusteitem  (idstockajusteitem INTEGER,  idstockajuste bigint,  saiimporteunitario double precision, idsigno integer,  saicantidad integer,  saiimportetotal double precision,   saialicuotaiva double precision,  saiimporteiva double precision,  saifechaingreso date ,  idusuario integer,  idarticulo integer,  saifechavencimiento date,  idcentrostockajuste integer ,  idcentrostockajusteitem integer ,  idcentroarticulo integer,  saicantidadactual integer,  saanulado boolean,  safecha timestamp,  sadescripcion character varying,  saesautomatico boolean ,  idstockajusteestadotipo integer,   operacion character varying );


	INSERT INTO temp_far_stockajusteitem (idusuario,idarticulo,idcentroarticulo,sadescripcion,saicantidadactual,saicantidad,idsigno) 
	(
	SELECT 
	rusuario.idusuario
        ,idarticulo,idcentroarticulo
        ,vobservacion as sadescripcion
	,far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) as stockactual
	,abs(psaicantidadcontada - far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo)) as saicantidad
	,case when psaicantidadcontada - far_darcantidadarticulostock(t.idarticulo, t.idcentroarticulo) < 0 then -1 else 1 end as idsigno
	FROM (
		select far_precargastockajusteitem.idarticulo,far_precargastockajusteitem.idcentroarticulo,sum(psaicantidadcontada) as psaicantidadcontada
		from far_precargastockajusteitem 
		NATURAL JOIN far_articulo as fa
		LEFT JOIN far_articulo as fap ON fa.idarticulo = fap.idarticulopadre AND fa.idcentroarticulo = fap.idcentroarticulopadre
		LEFT JOIN (SELECT idarticulo,idcentroarticulo,idstockajuste,idcentrostockajuste 
							FROM far_stockajusteitem
							NATURAL JOIN temp_comprobanteajuste_generados
							WHERE obs = 'Precarga'
						 ) as sa ON fa.idarticulo = sa.idarticulo AND fa.idcentroarticulo = sa.idcentroarticulo
			Where nullvalue(far_precargastockajusteitem.idstockajuste) 
			AND far_precargastockajusteitem.psaicantidadcontada<0
			AND nullvalue(sa.idstockajuste) --son los articulos que ya generaron movimiento de stock en la precarga
			AND far_darcantidadarticulostock(fa.idarticulo,fa.idcentroarticulo) <> 0 -- Si el stock es cero, quiere decir que no se usa 
			AND nullvalue(fap.idarticulo) --son los padres de los fraccionados 
			AND fa.aactivo --son los que se desactivaron durante la lectura
			and not psaiborrado --No estan marcados como borrados
			GROUP BY far_precargastockajusteitem.idarticulo,far_precargastockajusteitem.idcentroarticulo 
		) as t
	);

	
   SELECT INTO respuesta * FROM far_stockajustedesdetemporal_2();
   vidstockajuste = split_part(respuesta, '-',1) ::bigint;
   vidcentrostockajuste = split_part(respuesta, '-',2)::integer;
   UPDATE far_precargastockajusteitem SET idstockajuste	 = vidstockajuste
                                          ,idcentrostockajuste = vidcentrostockajuste
          WHERE  nullvalue(idstockajuste) 
                 AND (idprecargastockajusteitem,idcentroprecargastockajusteitem) IN (
			select idprecargastockajusteitem,idcentroprecargastockajusteitem
					from far_precargastockajusteitem 
					NATURAL JOIN far_articulo as fa
					LEFT JOIN far_articulo as fap ON fa.idarticulo = fap.idarticulopadre AND fa.idcentroarticulo = fap.idcentroarticulopadre
					LEFT JOIN (SELECT idarticulo,idcentroarticulo,idstockajuste,idcentrostockajuste 
							FROM far_stockajusteitem
							NATURAL JOIN temp_comprobanteajuste_generados
							WHERE obs = 'Precarga'
						 ) as sa ON fa.idarticulo = sa.idarticulo AND fa.idcentroarticulo = sa.idcentroarticulo
						Where nullvalue(far_precargastockajusteitem.idstockajuste) 
						AND far_precargastockajusteitem.psaicantidadcontada<0
						AND nullvalue(sa.idstockajuste) --son los articulos que ya generaron movimiento de stock en la precarga
						AND far_darcantidadarticulostock(fa.idarticulo,fa.idcentroarticulo) <> 0 -- Si el stock es cero, quiere decir que no se usa 
						AND nullvalue(fap.idarticulo) --son los padres de los fraccionados 
						AND fa.aactivo --son los que se desactivaron durante la lectura
						and not psaiborrado --No estan marcados como borrados
                 );
  
   return respuesta;

END;
$function$
