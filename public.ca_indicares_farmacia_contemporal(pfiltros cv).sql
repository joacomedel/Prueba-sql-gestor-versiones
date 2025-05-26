CREATE OR REPLACE FUNCTION public.ca_indicares_farmacia_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       --RECORD
	rfiltros RECORD;
/*Cantidad de Artículos controlados (picados)
Ajustes de Stock (cantidad registrados)
Ajustes de Stock (suma total: precio venta x cantidad)
Articulos Descartados por vencimiento (cantidad de articulos diferentes)
Articulos Descartados por vencimiento (cantidad x precio venta)
Importe Total (a cobrar) de Recetas vendidas en el mes
Importe Total (a cobrar) de Recetas liquidadas en el mes

*/

BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_ca_indicares_farmacia_contemporal (
cantarticulos INTEGER,
cantpicados INTEGER,
cantidadpicadosajustados INTEGER,
cantidadopsumas INTEGER,
cantidadoprestas INTEGER,
importetotalpicadoajustado double precision,
canitidaddescartados INTEGER,
importetotaldescartado double precision,
importerecetasvendidas double precision,
importerecetasliquidadas double precision,
mapeocampocolumna varchar
);

INSERT INTO temp_ca_indicares_farmacia_contemporal(mapeocampocolumna) VALUES('1-c_articulosconstock#cantarticulos@1-c_articulosPicados#cantpicados@2-c_ajustesStock#cantidadpicadosajustados@3-i_ajustesStock#importetotalpicadoajustado@4-c_articulosdescartados#canitidaddescartados@5-i_articulosdescartados#importetotaldescartado@6-i_recetasvendidas#importerecetasvendidas@7-i_recetasliquidadas#importerecetasliquidadas@8-c_cantidadopsumas#cantidadopsumas@9-c_cantidadoprestas#cantidadoprestas');

--Coloco los articulos que generaron algun movimiento en el periodo ingresado

UPDATE temp_ca_indicares_farmacia_contemporal SET cantarticulos = tt.cantidadarticulos
	 		FROM (
SELECT COUNT(*) as cantidadarticulos
                             FROM (
                                  select idarticulo,idcentroarticulo
                                  from far_articulo
                                  NATURAL JOIN far_lote
                                  NATURAL JOIN far_movimientostockitem
                                  NATURAL JOIN far_movimientostock
                                  where msfecha >= current_date - 365::integer
                                      AND msfecha <= current_date
                                      AND aactivo
                                  GROUP BY idarticulo,idcentroarticulo

) as total
) as tt;


--Coloco la cantidad de picados
UPDATE temp_ca_indicares_farmacia_contemporal SET cantpicados = tt.cantidadpicados
	 		FROM (
                             SELECT COUNT(*) as cantidadpicados
                             FROM (
                                  select idarticulo,idcentroarticulo
                                  from far_precargastockajusteitem 
                                  where psaiaifechaingreso >= rfiltros.fechadesde
                                      AND psaiaifechaingreso <= rfiltros.fechahasta 
                                      AND not psaiborrado
                                  GROUP BY idarticulo,idcentroarticulo
                                ) as total
                         ) as tt;

--Determino el costo de los ajustes

UPDATE temp_ca_indicares_farmacia_contemporal SET cantidadpicadosajustados = tt.cantidadpicadosajustados,
							  cantidadopsumas = tt.cantidadsumas,
							  cantidadoprestas = tt.cantidadrestas,
							  importetotalpicadoajustado = tt.importetotal
		FROM (
SELECT count(*) cantidadpicadosajustados ,sum(cantidadsumas) as cantidadsumas,sum(cantidadrestas) as cantidadrestas,sum(importetotal) as importetotal
FROM (
SELECT idarticulo,idcentroarticulo,sum(CASE WHEN idsigno > 0 THEN 1 ELSE 0 END) as cantidadsumas,sum(CASE WHEN idsigno < 0 THEN 1 ELSE 0 END) as cantidadrestas,sum(saiimportetotal) as importetotal
FROM far_stockajusteitem 
NATURAL JOIN (
SELECT DISTINCT idstockajuste,idcentrostockajuste
FROM (
select idarticulo,idcentroarticulo,idstockajuste,idcentrostockajuste
from far_precargastockajusteitem 
where psaiaifechaingreso >= rfiltros.fechadesde
   AND psaiaifechaingreso <= rfiltros.fechahasta 
   AND not psaiborrado AND not nullvalue(idstockajuste)
GROUP BY idarticulo,idcentroarticulo,idstockajuste,idcentrostockajuste
) as t
) as ttt
WHERE saicantidad <> 0
GROUP BY idarticulo,idcentroarticulo
) as t
) as tt;

--Coloco la informacion de los vencidos

UPDATE temp_ca_indicares_farmacia_contemporal SET canitidaddescartados = tt.canitidaddescartados,
							  importetotaldescartado = tt.importetotaldescartado
		FROM (
                      SELECT COUNT(*) as canitidaddescartados,sum(importetotaldescartado) as importetotaldescartado
                      FROM (
                           SELECT idarticulo,idcentroarticulo,sum(saiimportetotal) as importetotaldescartado
                           FROM far_stockajuste 
                           NATURAL JOIN far_stockajusteitem
                           WHERE not saesautomatico AND safecha::date >= rfiltros.fechadesde AND safecha <= rfiltros.fechahasta 
                                 AND sadescripcion ilike '%VENC%'
                                 GROUP BY idarticulo,idcentroarticulo
                             ) as t
                    ) as tt;

--Coloco la informacion de las liquidaciones
	UPDATE temp_ca_indicares_farmacia_contemporal SET importerecetasvendidas = T.importerecetasvendidas,
							  importerecetasliquidadas = T.importerecetasliquidadas
		FROM (
			SELECT sum(oviimonto) as importerecetasvendidas
, sum(CASE WHEN NOT nullvalue(fliovii.idordenventaitem) THEN oviimonto ELSE 0 END) AS importerecetasliquidadas

			FROM far_ordenventa o NATURAL JOIN far_ordenventaitem fovi NATURAL JOIN far_ordenventaitemimportes fovii NATURAL JOIN far_ordenventatipo
			NATURAL JOIN far_ordenventaestado LEFT JOIN far_liquidacionitemovii as fliovii USING(idordenventaitem,idcentroordenventaitem, idordenventaitemimporte ,idcentroordenventaitemimporte) 
			WHERE ovfechaemision::date >= rfiltros.fechadesde AND ovfechaemision::date <= rfiltros.fechahasta AND 
--KR 31-01-20 me quedo solo con las recetas facturadas
idvalorescaja <>0 AND ovtfacturable AND nullvalue(ovefechafin) AND idordenventaestadotipo=3
--<>2
			 
		) AS T;
return 'true';
END;
$function$
