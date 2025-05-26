CREATE OR REPLACE FUNCTION public.far_migrararticulos2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*	cursorarticulos CURSOR FOR SELECT *
               FROM far_productotmp
               WHERE nullvalue(migrado)
                     and not nullvalue(codinterno);*/
                    -- and trim(both ' ' from codinterno) not like  '%%' ;
   	cursorarticulos CURSOR FOR SELECT * 
                           FROM tfar_tempmigrar
                                JOIN far_articulo_2 USING (idarticulo)
                                JOIN far_rubro using (idrubro)
                           WHERE aprocesado; -- esta variable toma el valor True cuando se releva el articulo

	rarticulo RECORD;
	rartexistente record;
	elidmovimientostock integer;
	elidarticulo bigint;
	elidlote integer;
	elidajuste  integer;
	resp boolean;

BEGIN
/*Creo un moviminto en el que se van a colocar todos los propuctos pmigrados*/
/* El proceso de migracion
1- crea un ajuste  interno que va a contener como items a todos los articulosde la migracion
2- cierra el ajuste
3- se crea un nuevo movimiento de tipo migracion que va a disparar el triger que afecta al stock

*/


    INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion) VALUES (false, now(),concat('GA - X proceso de migracion ',now()));
    elidajuste =  currval('far_stockajuste_idstockajuste_seq');
    INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , eaefechaini)VALUES(5,elidajuste,now());

    OPEN cursorarticulos;
    FETCH cursorarticulos into rarticulo;
    WHILE  found LOOP
    

                 -- Verifico si hay informacion cargada del articulo
                 SELECT INTO rartexistente *
                        FROM far_articulo WHERE acodigobarra =rarticulo.acodigobarra;
                 IF NOT FOUND THEN
                              INSERT INTO far_articulo (idrubro,adescripcion,  astockmin,astockmax, acomentario, acodigointerno ,adescuento,acodigobarra)
                                     VALUES (rarticulo.idrubro,rarticulo.adescripcion,1,10000,concat('- migrado ',now(),' segun relevamiento de farmacia -'),rarticulo.acodigointerno::bigint,0,
                                     rarticulo.acodigobarra);
                              elidarticulo = currval('public.far_articulo_idarticulo_seq');
                              INSERT INTO far_precioarticulo (idarticulo, pafechaini,pavalor,pvalorcompra)
                                     VALUES(elidarticulo,now(),round ((rarticulo.aprecioventa/1.21)::numeric,2), rarticulo.aprecioventa);

                            

                  ELSE
                        elidarticulo = rartexistente.idarticulo;
                       -- UPDATE far_lote
                       -- SET lstock =lstock + rarticulo.acantidad
                       --   SET lstock = rarticulo.acantidad
                          -- ,lfechavencimiento =  rarticulo.afechavencimiento
                        --WHERE idarticulo = elidarticulo;
                        
                        UPDATE far_precioarticulo
                        SET pavalor = round ((rarticulo.aprecioventa/1.21)::numeric,2)
                        WHERE idarticulo = elidarticulo ;
                  END IF;
                                                    --    far_articulo_2.aprecioventa
                  INSERT INTO far_stockajusteitem(idstockajuste,saiimporteunitario,idsigno,
                                     saicantidad,saiimportetotal,saialicuotaiva,saiimporteiva,saifechaingreso,idusuario,
                                     idarticulo,saifechavencimiento)
                                     VALUES(elidajuste,rarticulo.aprecioventa* rarticulo.acantidad ,
                                            1,rarticulo.acantidad,rarticulo.aprecioventa,
                                            rarticulo.rporcentajeganacia,round ((rarticulo.aprecioventa/1.21)::numeric,2),now()
                                            ,4,elidarticulo,rarticulo.afechavencimiento);

                  UPDATE far_articulo_2
                  SET acantidad = 0, afechamigracion = now()
                  WHERE acodigobarra = rarticulo.acodigobarra;
    /*    Esto deberia estar en el triger que provoca las modificaciones en el stock */
    fetch cursorarticulos into rarticulo;
    END LOOP;
    close cursorarticulos;

    CREATE TEMP TABLE far_movimientostocktmp(msdescripcion VARCHAR,idmovimientostocktipo INTEGER);
    INSERT INTO far_movimientostocktmp (msdescripcion ,idmovimientostocktipo)VALUES(concat('Migracion masiva realizada far_migrararticulos',now()) ,1);
    SELECT INTO resp  far_movimientostocknuevo ('far_stockajuste', elidajuste::varchar);


return 'true';
END;
$function$
