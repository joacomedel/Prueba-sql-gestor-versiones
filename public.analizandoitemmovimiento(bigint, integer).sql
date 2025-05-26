CREATE OR REPLACE FUNCTION public.analizandoitemmovimiento(bigint, integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

       comajuste record ;
       cantitemajuste integer;
       cantitemmovimiento integer;

BEGIN
     -- Dado un movimiento stock busco el comprobante de ajuste que lo origino
     SELECT INTO comajuste idcentrostockajuste , idstockajuste
     FROM far_movimientostockitem
     NATURAL JOIN  far_movimientostockitemstockajuste
     NATURAL JOIN far_stockajusteitem
     WHERE idmovimientostock = $1 and idcentromovimientostock = $2;
     
     SELECT INTO cantitemajuste count(*)
     FROM far_stockajusteitem
     WHERE idcentrostockajuste = comajuste.idcentrostockajuste
           and idstockajuste = comajuste.idstockajuste
     GROUP BY idstockajuste , idcentrostockajuste ;
     
     SELECT INTO cantitemmovimiento count(*)
     FROM far_movimientostockitem
     WHERE idmovimientostock = $1
           and idcentromovimientostockitem = $2
     GROUP BY  idcentromovimientostockitem , idmovimientostock;

     IF (cantitemmovimiento <> cantitemajuste )  THEN
           INSERT INTO resutltadoanalisiscompajuste (idmovimientostock  , idcentromovimientostock ,
                        idstockajuste ,idcentrostockajuste ,descripcion ,   cantitemmov , cantitemajus  )
            VALUES ($1 , $2,
                         comajuste.idstockajuste ,comajuste.idcentrostockajuste ,'no coinciden las cantidades: ', cantitemmovimiento  ,  cantitemajuste  );

     
     END IF;


  
     return 'Listo';
END;
$function$
