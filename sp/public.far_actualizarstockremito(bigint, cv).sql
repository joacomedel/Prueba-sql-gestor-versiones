CREATE OR REPLACE FUNCTION public.far_actualizarstockremito(bigint, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       ccomprobanteitem refcursor;
       rcomprobanteitem record;
       codmovimientostock bigint;
       codremito bigint;
       codlote bigint;
       codmovitem bigint;
       idremito bigint;
       resp boolean;
BEGIN
     codmovimientostock =$1;
     idremito = $2;
     SELECT INTO codremito split_part(idremito, '|',1);
     /* Esta temporal va a contener las claves de los lotes que fueron afectados con el movimiento*/
     CREATE TEMP TABLE movimientostockitemtmp(idmovimientostockitem bigint);
   -- recupero todos los items del remito
     OPEN ccomprobanteitem FOR  SELECT *
                          FROM far_remitoitem WHERE idremito = codremito;

     FETCH ccomprobanteitem into rcomprobanteitem;
     WHILE  found LOOP
                   SELECT INTO resp  far_articulomoverstock
                   (rcomprobanteitem.idarticulo,rcomprobanteitem.fvicantidad,0,rcomprobanteitem.fvifechavencimiento,codmovimientostock);

                   INSERT INTO far_movimientostockitemremito(idmovimientostockitem,idmovimientostockitemremito)
                               SELECT idmovimientostockitem, rcomprobanteitem.idstockajusteitem
                               FROM movimientostockitemtmp;

                   fetch ccomprobanteitem into rcomprobanteitem;
      END LOOP;
      close ccomprobanteitem;
      
   return 'true';
END;
$function$
