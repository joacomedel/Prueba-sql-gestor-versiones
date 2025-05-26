CREATE OR REPLACE FUNCTION public.far_abmarticulo_paraborrar()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
cursorarticulos CURSOR FOR SELECT *
                           FROM far_articulo_temp;
                          
        rarticulo RECORD;
	rartexistente record;
	rprecioventa record;
	elidarticulo bigint;
	rprecioventavalor double precision;
        elidajuste bigint;
        resp boolean;
        existelote record;
        rtipoiva RECORD;
        existecodba RECORD;
        rprecioarticulopadre RECORD;
        vporcentaje double precision;
        vporcentajemasuno double precision;
        vctacble varchar;
        precio RECORD;
        rusuario RECORD;
                          
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
                           
OPEN cursorarticulos;
FETCH cursorarticulos into rarticulo;
WHILE  found LOOP
SELECT INTO rtipoiva * FROM tipoiva WHERE idiva = rarticulo.idiva;
vporcentaje =  rtipoiva.porcentaje;
vporcentajemasuno = 1.0 + rtipoiva.porcentaje;
IF rtipoiva.idiva = 1 THEN 
   vctacble = '41200';
ELSE
   vctacble = '41100';

END IF;



IF (nullvalue(rarticulo.idarticulo)) THEN
-- El producto no existe y es nuevo
     INSERT INTO far_articulo (actacble,idiva,idrubro,adescripcion,  astockmin,astockmax, acomentario, acodigointerno ,adescuento,acodigobarra,apreciokairos,idarticulopadre,afraccion,afactorcorreccion)
      VALUES (vctacble,rarticulo.idiva,rarticulo.idrubro,rarticulo.adescripcion,rarticulo.astockmin,rarticulo.astockmax,
      concat(rarticulo.acomentario , '-Cargado ',now(),'-'),currval('public.far_articulo_idarticulo_seq')*1000::bigint+centro()                       ,rarticulo.adescuento,rarticulo.acodigobarra,
      rarticulo.apreciokairos,rarticulo.idarticulopadre,rarticulo.afraccion,rarticulo.afactorcorreccion);
      elidarticulo = currval('public.far_articulo_idarticulo_seq');
      UPDATE far_articulo_temp SET idarticulo = elidarticulo WHERE acodigobarra =rarticulo.acodigobarra AND  adescripcion = rarticulo.adescripcion;
      rarticulo.idarticulo = elidarticulo;

     



ELSE
    IF (rarticulo.accion = 'Eliminar') THEN
    --Existe y tengo que eliminarlo, solo puedo eliminarlo si es que no se vendio nunca. La FK me bloquea el borrado.
       DELETE FROM far_precioarticulo WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
       
       DELETE FROM far_precioarticulosugerido WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
       DELETE FROM far_preciocompra WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
       DELETE FROM far_articulo WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;
     ELSE
     --El producto existe y hay que actualizarlo.
       
       SELECT INTO existecodba *  FROM far_articulo WHERE acodigobarra= rarticulo.acodigobarra;
       IF NOT FOUND AND centro() <> rarticulo.idcentroarticulo THEN 
           INSERT INTO far_articulo (actacble,idiva,idrubro,adescripcion,  astockmin,astockmax, acomentario, acodigointerno  ,afactorcorreccion,adescuento,acodigobarra,apreciokairos,idarticulopadre,afraccion,idarticulo, idcentroarticulo)
      VALUES (vctacble,rarticulo.idiva,rarticulo.idrubro,rarticulo.adescripcion,rarticulo.astockmin,rarticulo.astockmax,rarticulo.acomentario     ,rarticulo.acodigointerno  ,rarticulo.afactorcorreccion,rarticulo.adescuento,rarticulo.acodigobarra,      rarticulo.apreciokairos,rarticulo.idarticulopadre,rarticulo.afraccion,rarticulo.idarticulo,rarticulo.idcentroarticulo);
      elidarticulo = rarticulo.idarticulo;
      UPDATE far_articulo_temp SET idarticulo = elidarticulo WHERE acodigobarra =rarticulo.acodigobarra AND  adescripcion = rarticulo.adescripcion;
      rarticulo.idarticulo = elidarticulo;


       ELSE
        UPDATE far_articulo SET idrubro = rarticulo.idrubro
                            ,adescripcion=rarticulo.adescripcion
                            ,astockmin=rarticulo.astockmin
                            ,astockmax=rarticulo.astockmax
                            ,acomentario=rarticulo.acomentario
                            ,idiva =rarticulo.idiva
                            ,adescuento=rarticulo.adescuento
                            ,acodigointerno=rarticulo.acodigointerno
                            ,acodigobarra =rarticulo.acodigobarra
                            ,apreciokairos =rarticulo.apreciokairos
                            ,afraccion = rarticulo.afraccion
                            ,afactorcorreccion  = rarticulo.afactorcorreccion
                            ,idarticulopadre = rarticulo.idarticulopadre
                            ,actacble = vctacble 
                            WHERE idarticulo = rarticulo.idarticulo
                                  AND idcentroarticulo = rarticulo.idcentroarticulo;
        END IF;
       
END IF;
END IF;



SELECT INTO existelote * FROM far_lote WHERE idarticulo = rarticulo.idarticulo AND idcentroarticulo= rarticulo.idcentroarticulo ;
IF NOT FOUND THEN 
INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('Alta de Articulo ',now()));
elidajuste =  currval('far_stockajuste_idstockajuste_seq');
INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , eaefechaini)VALUES(5,elidajuste,now());

INSERT INTO far_stockajusteitem(idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal
,saialicuotaiva,saiimporteiva,saifechaingreso,idusuario,idarticulo,idcentroarticulo,saifechavencimiento)
VALUES(elidajuste,rarticulo.aprecioventa,1,0,rarticulo.aprecioventa,0,round((rarticulo.aprecioventa/vporcentajemasuno)::numeric,2)
,now(),rarticulo.idusuario,rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.afechavto);

IF NOT  iftableexists('far_movimientostocktmp') THEN 

CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
ELSE

DELETE FROM far_movimientostocktmp;
END IF;

INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)
VALUES(concat('Alta de Articulo por far_abmarticulo',now(), 'IDAjuste ', elidajuste::varchar) ,1);
SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);

END IF;

fetch cursorarticulos into rarticulo;
END LOOP;
close cursorarticulos;

 SELECT INTO resp * FROM far_preciosugerido_en_abmarticulo();

return true;

END;
$function$
