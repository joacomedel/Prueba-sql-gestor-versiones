CREATE OR REPLACE FUNCTION public.far_stockajustedecopahueanqn()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE

    elidajuste  integer;
    respuesta varchar;
BEGIN

       respuesta = '';

      --Genero el Comprobante de Ingreso
     INSERT INTO far_stockajuste(saanulado,safecha,sadescripcion)
        (SELECT false, now(),
     concat(   'GA - Ingreso Productos sobrantes de Copahue temporada 2015. Este comprobante de Ajuste se Genero usando los comprobantes de Ajustes generados en Copahue.   \n  Los comprobantes son: ***   '
     ,     text_concatenar(idstockajuste  , '-' ,far_stockajuste.idcentrostockajuste  )  ) as motivo
    FROM far_stockajuste /* LEFT JOIN (SELECT sum(saiimporteunitario) as saiimporteunitario,sum(saicantidad) as saicantidad 				,sum(saiimportetotal) as saiimportetotal,sum(saiimporteiva) as saiimporteiva,idstockajuste,idcentrostockajuste   				FROM far_stockajusteitem 				GROUP BY idcentrostockajuste,idstockajuste ) as far_stockajusteitem USING(idstockajuste,idcentrostockajuste)*/  NATURAL JOIN far_stockajusteestado  NATURAL JOIN far_stockajusteestadotipo  LEFT JOIN far_stockajusteremito USING(idstockajuste,idcentrostockajuste)  
WHERE   nullvalue(eaefechafin) AND  true   AND safecha >=  '2015-04-11'  AND 
idcentrostockajuste =14 and idstockajusteestadotipo<>3 and not saesautomatico



       );
       elidajuste =  currval('far_stockajuste_idstockajuste_seq');
       respuesta = concat(   respuesta , elidajuste,'-',centro() , '|');

           INSERT INTO far_stockajusteestado (idstockajusteestadotipo, idstockajuste , idcentrostockajuste,eaefechaini)
                  VALUES(1,elidajuste,centro(),now());
           --Lo voy a dejar en estado Creado, para que alguien lo tenga que cerrar

           INSERT INTO far_stockajusteitem (idstockajuste,saiimporteunitario,idsigno,saicantidad,saiimportetotal,idarticulo,idcentroarticulo,saialicuotaiva,saiimporteiva,idusuario,saicantidadactual)
                   ( SELECT elidajuste,  saiimporteunitario ,idsigno*-1,  saicantidad
                     , saiimportetotal,idarticulo,idcentroarticulo
                     ,saialicuotaiva,saiimporteiva
                     ,25 AS idusuario,far_darcantidadarticulostock(idarticulo,idcentroarticulo) AS saicantidadactual  FROM far_stockajuste  NATURAL JOIN far_stockajusteitem   NATURAL JOIN far_stockajusteestado  NATURAL JOIN far_stockajusteestadotipo  LEFT JOIN far_stockajusteremito USING(idstockajuste,idcentrostockajuste)  
WHERE   nullvalue(eaefechafin) AND  true   AND safecha >=  '2015-04-11'  AND 
idcentrostockajuste =14 and idstockajusteestadotipo<>3 and not saesautomatico and not nullvalue(saiimporteunitario)
ORDER BY idcentrostockajuste,idstockajuste DESC 

                   );




return respuesta;

END;
$function$
