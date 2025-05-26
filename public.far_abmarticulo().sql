CREATE OR REPLACE FUNCTION public.far_abmarticulo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


    cursorarticulos CURSOR FOR SELECT *FROM far_articulo_temp;
           
    -- RECORD
    --precio RECORD;
    rusuario RECORD;
    rarticulo RECORD;
	rartexistente RECORD;
	rprecioventa RECORD;
    existelote RECORD;
    rtipoiva RECORD;
    existecodba RECORD;
    rprecioarticulopadre RECORD;

	elidarticulo bigint;
	rprecioventavalor double precision;
    elidajuste bigint;
    resp boolean;
    vporcentaje double precision;
    vporcentajemasuno double precision;
    vctacble varchar;
    inserte boolean; 
                          
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
            INSERT INTO far_articulo   ( actacble,idiva,idrubro,adescripcion,  astockmin,astockmax, acomentario, acodigointerno ,adescuento,acodigobarra,apreciokairos,idarticulopadre,idcentroarticulopadre,afraccion,afactorcorreccion)
            VALUES (vctacble,rarticulo.idiva,rarticulo.idrubro,rarticulo.adescripcion,rarticulo.astockmin,rarticulo.astockmax,
                concat(rarticulo.acomentario , '-Cargado ',now(),'-'),currval('public.far_articulo_idarticulo_seq')*1000::bigint+centro(),rarticulo.adescuento,rarticulo.acodigobarra,
                rarticulo.apreciokairos,rarticulo.idarticulopadre,rarticulo.idcentroarticulopadre,rarticulo.afraccion,rarticulo.afactorcorreccion);
      
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
                IF (rarticulo.accion = 'modificacodigobarra') THEN
                    -- 29-09-2016 Malapi Para modificar el codigo de barra, hay que hacerlo desde una interfaz especial
                    UPDATE far_articulo SET acodigobarra = rarticulo.acodigobarra WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo;

                    UPDATE medicamento SET mcodbarra= rarticulo.acodigobarra WHERE (mnroregistro,true) IN (
                        SELECT mnroregistro,nomenclado
                        FROM far_medicamento
                        WHERE idarticulo =rarticulo.idarticulo AND idcentroarticulo = rarticulo.idcentroarticulo
                    );

                ELSE 
                    --El producto existe y hay que actualizarlo.
                    -- 09-09-2016 Malapi Se puede cambiar el código de barra de un articulo, no es necesario cargar un nuevo articulo
                    -- para poder cambiar el codigo de barras.
                    UPDATE far_articulo 
                        SET 
                            idrubro = rarticulo.idrubro
                            ,adescripcion=rarticulo.adescripcion
                            ,astockmin=rarticulo.astockmin
                            ,astockmax=rarticulo.astockmax
                            ,acomentario=rarticulo.acomentario
                            ,idiva =rarticulo.idiva
                            ,adescuento=rarticulo.adescuento
                            ,acodigointerno=rarticulo.acodigointerno
                            ,apreciokairos =rarticulo.apreciokairos
                            ,afraccion = rarticulo.afraccion
                            ,afactorcorreccion  = rarticulo.afactorcorreccion
                            ,idarticulopadre = rarticulo.idarticulopadre
                            ,idcentroarticulopadre = rarticulo.idcentroarticulopadre
                            ,actacble = vctacble 
                            ,aactivo = rarticulo.activo 
                    WHERE 
                        idarticulo = rarticulo.idarticulo
                        AND idcentroarticulo = rarticulo.idcentroarticulo;

                    --Dani modifico el 22/05/17 para q cuando se desactiva un articulo,tmb se limpie el acodigobarra
                    IF NOT(rarticulo.activo )THEN
                        UPDATE far_articulo 
                        SET acodigobarra =null 
                        WHERE 
                            idarticulo =rarticulo.idarticulo
                            AND idcentroarticulo = rarticulo.idcentroarticulo;
                    END IF;

                END IF;   
            END IF;
        END IF;

        SELECT INTO existelote * FROM far_lote WHERE idarticulo = rarticulo.idarticulo AND idcentroarticulo= rarticulo.idcentroarticulo ;

        IF NOT FOUND THEN 
            INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('Alta de Articulo ',now()));
            
            elidajuste =  currval('far_stockajuste_idstockajuste_seq');
            INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , eaefechaini)VALUES(5,elidajuste,now());

            INSERT INTO far_stockajusteitem(idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,saialicuotaiva,saiimporteiva,saifechaingreso,idusuario,idarticulo,idcentroarticulo,saifechavencimiento)
            VALUES(elidajuste,rarticulo.aprecioventa,1,0,rarticulo.aprecioventa,0,round((rarticulo.aprecioventa/vporcentajemasuno)::numeric,2),now(),rarticulo.idusuario,rarticulo.idarticulo,rarticulo.idcentroarticulo,rarticulo.afechavto);

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

END;$function$
