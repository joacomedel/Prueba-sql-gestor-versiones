CREATE OR REPLACE FUNCTION public.far_actualizarstockfacturaventa(bigint, character varying)
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
       idcomprobante varchar;
       elnrofactura  bigint;
       eltipocomprobante integer;
       elnrosucursal integer;
       eliditem  bigint;
       eltipofactura varchar;
       resp boolean;
       operacion integer;
BEGIN
     codmovimientostock =$1;
     idcomprobante = $2;

     -- recupero la clave de la facturaventa
     --- concat(elem.sgtenumero ,'|' ,rnotacredito.tipocomprobante, '|', rnotacredito.nrosucursal, '|',  rnotacredito.tipofactura
     SELECT INTO elnrofactura split_part(idcomprobante, '|',1);
     SELECT INTO eltipocomprobante split_part(idcomprobante, '|',2);
     SELECT INTO elnrosucursal split_part(idcomprobante, '|',3);
     SELECT INTO eltipofactura split_part(idcomprobante, '|',4);



     -- Si el tipo de comprobante es una NC => el movimiento de stock debe ser un incremento = +1
     -- Si el tipo de comprobante es una TK  => el movimiento de stock debe ser un decremento = -1
     operacion = -1;
     IF( eltipofactura ='NC') THEN
              operacion = 1;
     END IF;

     /* Esta temporal va a contener las claves de los lotes que fueron afectados con el movimiento*/
     CREATE TEMP TABLE movimientostockitemtmp(idmovimientostockitem bigint);
     OPEN ccomprobanteitem FOR  SELECT *
                          FROM itemfacturaventa
                          NATURAL JOIN  far_ordenventaitemitemfacturaventa
                          NATURAL JOIN  far_ordenventaitem

                          WHERE nrofactura = elnrofactura
                          and tipocomprobante = eltipocomprobante
                          and nrosucursal = elnrosucursal
                          and tipofactura = eltipofactura ;
                          
     FETCH ccomprobanteitem into rcomprobanteitem;
     WHILE  found LOOP
                    -- GK modifico ovcantdevueltas por ovicantidad para corregir problema de articulo iguales en ordenes distintas 
                    -- lo cual generaba error de stock  
                   SELECT INTO resp  far_articulomoverstock
                   (rcomprobanteitem.idarticulo,rcomprobanteitem.idcentroarticulo,rcomprobanteitem.ovicantidad ,operacion,null,codmovimientostock);
                   INSERT INTO far_movimientostockitemfactventa(idmovimientostockitem,
                    nrofactura ,nrosucursal,tipocomprobante,tipofactura,iditem)
                          SELECT idmovimientostockitem, elnrofactura , elnrosucursal,eltipocomprobante,eltipofactura,rcomprobanteitem.iditem
                          FROM movimientostockitemtmp;
                   DELETE FROM movimientostockitemtmp;
                   fetch ccomprobanteitem into rcomprobanteitem;
      END LOOP;

      close ccomprobanteitem;
return 'true';
END;
$function$
