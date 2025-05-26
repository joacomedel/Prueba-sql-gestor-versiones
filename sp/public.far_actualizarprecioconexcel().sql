CREATE OR REPLACE FUNCTION public.far_actualizarprecioconexcel()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*Actualiza los valores de los articulos de farmacias que son informados con un excel
que tiene en alguna de sus columnas las palabras precio y barra.
Solo modifico si el nuevo valor es mas alto que el anterior.
26-07-2013 Malapi Modifico para que al precio de venta propuesta siempre le incremente el 10%, ya no
se usa el % de ganancia del rubro, pues estamos cargando precios de venta al publico
04-10-2016 Malapi: Modifico para que se mande por parametro si se envia un precio de compra o de venta. 
04-10-2016 Malapi: El precio resultate, lo dejo como un precio sugerido, alguien lo tiene que poner en produccion. 
*/
 alta refcursor;
 resp boolean;   
 elem RECORD;
 rprecioarticulo RECORD;
 rusuario RECORD;
 rarchivo RECORD;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

CREATE TEMP TABLE far_articulo_temp (   idarticulo bigint,  idrubro INTEGER,   adescripcion VARCHAR,   astockmin DOUBLE PRECISION ,  astockmax DOUBLE PRECISION ,  acomentario TEXT,   idiva BIGINT,  adescuento DOUBLE PRECISION,  acodigointerno BIGINT,  acodigobarra VARCHAR,  apreciokairos BOOLEAN DEFAULT false,  afechavto DATE,  aprecioventa DOUBLE PRECISION,  accion VARCHAR,  idarticulopadre bigint,  idcentroarticulopadre INTEGER,  afraccion DOUBLE PRECISION DEFAULT 1,  afactorcorreccion DOUBLE PRECISION DEFAULT 1,  apreciocompra DOUBLE PRECISION,   idcentroarticulo INTEGER DEFAULT centro(),   idusuario INTEGER,   idprecioarticulosugerido INTEGER,   idcentroprecioarticulosuerido INTEGER,  motivo  VARCHAR,  activo boolean  DEFAULT true ,idfilename varchar,transaccion varchar,fila integer,codigobarra varchar,precio double precision,tipoprecio varchar) ;

SELECT INTO rprecioarticulo * FROM far_temprecioarticulo LIMIT 1;

IF rprecioarticulo.tipoprecio = 'comprasiniva' THEN
--Precio de Compra sin iva es lo que se esta enviando desde el excel, se usa el % de ganancia del rubro
OPEN alta FOR select precio as apreciocompra,round(((precio * r.rporcentajeganacia)+precio)::numeric,2)  as preciosiniva
		,round((((precio * r.rporcentajeganacia)+precio) * porcentaje)::numeric,2)  as importeiva, round((((precio * r.rporcentajeganacia)+precio) + round((((precio * r.rporcentajeganacia)+precio) * porcentaje)::numeric,2))::numeric,2) as importeconiva 
  ,a.*,pa.*,t.tipoprecio, t.fila ,t.codigo,t.precio
 from far_articulo a
 NATURAL JOIN tipoiva
 NATURAL JOIN far_rubro as r
 JOIN far_precioarticulo pa ON pa.idarticulo = a.idarticulo and pa.idcentroarticulo = a.idcentroarticulo and nullvalue(pafechafin)
 join far_temprecioarticulo as t on acodigobarra = codigo and codigo <> 0
 WHERE round(((precio * r.rporcentajeganacia)+precio)::numeric,2) > pavalor ;

END IF;



-- GK 23-05-2022 - Actualizo para tener encuenta el rubro al momento de calcular el precio de venta

IF rprecioarticulo.tipoprecio = 'ventasiniva' THEN
--Precio de Venta sin iva es lo que se esta enviando desde el excel
OPEN alta FOR 
  SELECT 
      0.0 as apreciocompra,
      precio as preciosiniva, 
      round((precio* porcentaje)::numeric,2)  as importeiva, 
      round((precio + round((precio* porcentaje)::numeric,2))::numeric,2) as importeconiva ,
      a.*,
      pa.*,
      t.tipoprecio, t.fila ,t.codigo,t.precio
 from far_articulo a
 NATURAL JOIN tipoiva
 NATURAL JOIN far_rubro as r
 JOIN far_precioarticulo pa ON pa.idarticulo = a.idarticulo and pa.idcentroarticulo = a.idcentroarticulo and nullvalue(pafechafin)
 join far_temprecioarticulo as t on acodigobarra = codigo and codigo <> 0
 WHERE precio > pavalor;

END IF;

IF rprecioarticulo.tipoprecio = 'ventaconiva' THEN
--Precio de Venta sin iva es lo que se esta enviando desde el excel
OPEN alta FOR select 0.0 as apreciocompra,round((precio / (1.0 + porcentaje))::numeric,2) as preciosiniva, round((precio - (precio / (1 + porcentaje)) )::numeric,2)  as importeiva, precio as importeconiva 
  ,a.*,pa.*,t.tipoprecio, t.fila ,t.codigo,t.precio
 from far_articulo a
 NATURAL JOIN tipoiva
 NATURAL JOIN far_rubro as r
 JOIN far_precioarticulo pa ON pa.idarticulo = a.idarticulo and pa.idcentroarticulo = a.idcentroarticulo and nullvalue(pafechafin)
 join far_temprecioarticulo as t on acodigobarra = codigo and codigo <> 0
 WHERE round((precio / (1.0 + porcentaje))::numeric,2) > pavalor ;

END IF;

FETCH alta INTO elem;
WHILE found LOOP
--Malapi el campo aprecioventa el SP far_preciosugerido_en_abmarticulo asume que es precio de venta con iva.
--INSERT INTO far_articulo_temp(idarticulo,idcentroarticulo,idiva,accion,aprecioventa,afraccion,afactorcorreccion,idarticulopadre,idcentroarticulopadre,apreciocompra,idusuario) 
--VALUES (elem.idarticulo,elem.idcentroarticulo,elem.idiva,'cargarpreciosexcel',elem.importeconiva,CASE when nullvalue(elem.afraccion) THEN 1 ELSE elem.afraccion END,CASE when nullvalue(elem.afactorcorreccion) THEN 1 ELSE elem.afactorcorreccion END,elem.idarticulopadre,elem.idcentroarticulopadre,elem.apreciocompra,rusuario.idusuario);

INSERT INTO far_articulo_temp(idarticulo,idcentroarticulo,idiva,accion,aprecioventa,afraccion,afactorcorreccion,idarticulopadre,idcentroarticulopadre,apreciocompra,idusuario,idfilename ,transaccion ,fila ,codigobarra,precio,tipoprecio  ) 
VALUES (elem.idarticulo,elem.idcentroarticulo,elem.idiva,'cargarpreciosexcel',elem.importeconiva,CASE when nullvalue(elem.afraccion) THEN 1 ELSE elem.afraccion END,CASE when nullvalue(elem.afactorcorreccion) THEN 1 ELSE elem.afactorcorreccion END,elem.idarticulopadre,elem.idcentroarticulopadre,CASE WHEN elem.apreciocompra = 0 THEN null ELSE elem.apreciocompra END,rusuario.idusuario,rprecioarticulo.idfilename ,rprecioarticulo.transaccion,elem.fila ,elem.codigo,elem.precio,rprecioarticulo.tipoprecio    );

 /* Modifico el precio viegente */
-- UPDATE far_precioarticulo SET pafechafin = now() WHERE far_precioarticulo.idprecioarticulo = elem.idprecioarticulo and nullvalue(far_precioarticulo.pafechafin) ;
 /* Inserto el nuevo valor */
-- INSERT INTO far_precioarticulo (idarticulo,pafechaini,pavalor,pimporteiva,pvalorcompra)
-- VALUES(elem.idarticulo,now(),elem.importesiniva,elem.importeiva,elem.importesiniva+elem.importeiva);

fetch alta into elem;
END LOOP;
CLOSE alta;

SELECT INTO resp * FROM far_preciosugerido_en_abmarticulo();

return 'true';
END;$function$
