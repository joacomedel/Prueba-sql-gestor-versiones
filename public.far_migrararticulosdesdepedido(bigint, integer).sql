CREATE OR REPLACE FUNCTION public.far_migrararticulosdesdepedido(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   	cursorarticulos CURSOR FOR SELECT CASE WHEN nullvalue(picantidadentregada) THEN 0 ELSE picantidadentregada END picantidadentregada, *,picantidad as cantpedido
                    FROM far_pedido
                    NATURAL JOIN far_pedidoitems
                    NATURAL JOIN far_articulo
                    NATURAL JOIN far_rubro
                    LEFT JOIN ( SELECT * FROM far_stockajusteitem NATURAL JOIN far_stockajuste 
                               WHERE sadescripcion ilike concat('GA - Proceso de Migracion por pedido ',$1,'/',$2) ) as sa USING(idarticulo,idcentroarticulo)
                    WHERE idpedido=$1 and idcentropedido=$2 AND nullvalue(sa.idarticulo) ;


	rarticulo RECORD;
	rartexistente record;
	raux record;
	elidmovimientostock integer;
	elidarticulo bigint;
	elidlote integer;
	elidajuste  integer;
	resp boolean;
	timportesiniva float4;
        timporteconiva float4;
	timporteiva float4;
        restado record;
        rusuario record;

BEGIN
/*MaLapi 22-01-2014 Se guarda el usuario que cierra el pedido al modificar el precio de venta de un producto*/

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


    /*Ma.La.Pi 24-06-2013 Cambio el estado en la BBDD. Dejo el pedido en estado Archivado*/
    SELECT INTO restado * FROM far_cambiarestadopedido(concat($1,'|',$2),3);

    INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('GA - Proceso de Migracion por pedido ',$1,'/',$2));
    elidajuste =  currval('far_stockajuste_idstockajuste_seq');
    INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , eaefechaini,idusuario)VALUES(5,elidajuste,now(),rusuario.idusuario);

    OPEN cursorarticulos;
    FETCH cursorarticulos into rarticulo;
    WHILE  found LOOP
                 -- Verifico si hay informacion cargada del articulo
                   SELECT INTO rartexistente  CASE WHEN nullvalue(pavalor) THEN pas.pasvalor ELSE pavalor END as pavalor
                                 ,CASE WHEN nullvalue(pimporteiva) THEN pas.pasimporteiva ELSE pimporteiva END as pimporteiva
                                ,CASE WHEN nullvalue(pvalorcompra) THEN pas.pasvalorcompra ELSE pvalorcompra END as pvalorcompra
                   ,a.idarticulo,idrubro,adescripcion,astockmin,astockmax,acomentario,idiva,adescuento,acodigointerno,acodigobarra,apreciokairos,actacble,idarticulopadre,afraccion,idprecioarticulo,pafechaini
,pafechafin,pamodificacion,a.idcentroarticulo,idcentroprecioarticulo,idusuariocarga,idprecioarticulosugerido,pasfechaini,pasfechafin,pasvaloranterior,idcentroprecioarticulosuerido,pasidusuariocarga,paspreciocompraprestador,pasmotivo
,case when nullvalue(lstock) then 0 else lstock end as lstock
                        FROM far_articulo as a
                   /*KR 30-11 Saco el left join porque si encuentra un lote con centro distinto a centro() no encuentra datos.  Y siempre quiero inserte en far_stockajusteitem para luego generar el lote en el movimiento. */
                       LEFT JOIN far_lote ON ( a.idarticulo = far_lote.idarticulo  AND a.idcentroarticulo =far_lote.idcentroarticulo AND far_lote.idcentrolote = centro() ) 


                        LEFT JOIN far_precioarticulo as pa ON pa.idarticulo = a.idarticulo AND pa.idcentroarticulo = a.idcentroarticulo AND nullvalue(pafechafin)
                        LEFT JOIN far_precioarticulosugerido as pas ON pas.idarticulo = a.idarticulo AND pas.idcentroarticulo = a.idcentroarticulo AND nullvalue(pasfechafin)
                        WHERE  /*(nullvalue(idcentrolote) OR idcentrolote = centro() ) AND*/
                    a.idarticulo = rarticulo.idarticulo AND a.idcentroarticulo = rarticulo.idcentroarticulo;


                 IF FOUND THEN
                        INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,saicantidadactual,idusuario)
VALUES(elidajuste,rartexistente.pavalor,1,rarticulo.picantidadentregada,rartexistente.pavalor * rarticulo.picantidadentregada,rarticulo.idarticulo,rarticulo.idcentroarticulo,0.21,rartexistente.pavalor*0.21,rartexistente.lstock,rusuario.idusuario);

 IF NOT rartexistente.apreciokairos THEN
SELECT INTO resp * FROM far_guardarpreciodesdepedido(rarticulo.idarticulo,rarticulo.idcentroarticulo,rusuario.idusuario);

END IF;

    
                       
                  END IF;
    fetch cursorarticulos into rarticulo;
    END LOOP;
    close cursorarticulos;
    CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
    INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Ingreso por Pedido ',$1,'-', $2) ,1);
    SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);


return 'true';
END;$function$
