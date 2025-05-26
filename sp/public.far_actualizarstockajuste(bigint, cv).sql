CREATE OR REPLACE FUNCTION public.far_actualizarstockajuste(bigint, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       ccomprobanteitem refcursor;
       rcomprobanteitem record;
       codmovimientostock bigint;
       elidstockajuste  bigint;
       elidcentrostockajuste varchar;
       idcomprobante varchar;
       resp boolean;
       operacion integer;
BEGIN
     codmovimientostock =$1;
     idcomprobante = $2;

     -- recupero la clave de la idstockajuste
     SELECT INTO elidstockajuste split_part(idcomprobante, '|',1);
--KR 10/02/15 
     --Malapi 10-02-2015 Comento pues me da un error al intentar vender un articulo fraccionado (BAYASPIRINA FORTE)
       --SELECT INTO elidcentrostockajuste  split_part(idcomprobante, '|',2);
--KR 11-02-15 MODIFIQUE NUEVAMENTE  ME VENDI EN DESARROLLO Y PRODUCCION ORDENES CON ARTICULOS SIN Y FRACCIONADOS
--         SELECT INTO elidcentrostockajuste  case when split_part(idcomprobante, '|',2) ilike '%%' THEN centro()::TEXT else split_part(idcomprobante, '|',2) END; 
--Malapi 03/10/2016 Comento y cambio, pues esta funcion asume que siempre el centro del comprobante es el centro de la bbdd*/ 
SELECT INTO elidcentrostockajuste  
         case when split_part(idcomprobante, '|',2) ilike '' THEN centro()::TEXT
         else split_part(idcomprobante, '|',2) END;


     /* Esta temporal va a contener las claves de los lotes que fueron afectados con el movimiento*/
IF NOT  iftableexists('movimientostockitemtmp') THEN

     CREATE TEMP TABLE movimientostockitemtmp(idmovimientostockitem bigint);

ELSE

DELETE FROM movimientostockitemtmp;

END IF;
     OPEN ccomprobanteitem FOR  SELECT *

                          FROM far_stockajusteitem

                          WHERE  idstockajuste = elidstockajuste  
                              AND idcentrostockajuste= elidcentrostockajuste ;
                         --AND idcentrostockajuste= centro() ;
     FETCH ccomprobanteitem into rcomprobanteitem;
     WHILE  found LOOP
                   SELECT INTO resp  far_articulomoverstock
                   (rcomprobanteitem.idarticulo,rcomprobanteitem.idcentroarticulo,rcomprobanteitem.saicantidad,rcomprobanteitem.idsigno,rcomprobanteitem.saifechavencimiento,codmovimientostock);

                   INSERT INTO far_movimientostockitemstockajuste( idmovimientostockitem,idstockajusteitem,idcentrostockajuste )
                          SELECT idmovimientostockitem, rcomprobanteitem.idstockajusteitem ,rcomprobanteitem.idcentrostockajusteitem
                          FROM movimientostockitemtmp;
                   DELETE FROM movimientostockitemtmp;

                   fetch ccomprobanteitem into rcomprobanteitem;
      END LOOP;

      close ccomprobanteitem;
return 'true';
END;
$function$
