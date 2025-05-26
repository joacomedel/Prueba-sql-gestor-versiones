CREATE OR REPLACE FUNCTION public.far_actualizarstock_manual_3()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    rcomprobante RECORD;
	ccomprobanteitem  refcursor;
	rcomprobanteitem RECORD;
	codremito varchar;
	elidmovimientostock bigint;
	resp boolean;
	
	cmovimientostock refcursor;
rmovimientostock  RECORD;


BEGIN
  /* OJO ESTE SP SOLO DEBE SER EJECUTADO MANUALMENTE CUANDO SE REQUIERA */

  --- 1 - Busco todos los movimientos de stock que no tengan item
   CREATE TEMP TABLE comprobatetmp(idmovimientostock bigint,nombretabla varchar ,id varchar);
   OPEN cmovimientostock FOR
                         SELECT far_movimientostock.*
                         FROM far_movimientostock
                         LEFT JOIN  far_movimientostockitem USING (idcentromovimientostock ,idmovimientostock)
                         WHERE nullvalue(far_movimientostockitem.idmovimientostock) and  (msfecha>= '2018-06-09')
                               and msdescripcion not ilike '%Alta de Articulo %'
                               and idcentromovimientostock =99
                              -- and msdescripcion   ilike '%Ingreso por Pedido%'
                               and idmovimientostock = 389498
	                  ORDER BY msfecha ;

     FETCH cmovimientostock into rmovimientostock;
     WHILE  found LOOP
            UPDATE  far_movimientostock
            SET msdescripcion= concat('<Siges ',to_char( now(),'DD/MM/YYYY HH24:MI:SS'),'> ',msdescripcion) WHERE idmovimientostock = rmovimientostock.idmovimientostock and idcentromovimientostock = 99;
            DELETE FROM comprobatetmp;
            INSERT INTO comprobatetmp (idmovimientostock , nombretabla ,id)VALUES(rmovimientostock.idmovimientostock , rmovimientostock.msnombretabla ,rmovimientostock.msidcomprobante );
            SELECT INTO rcomprobante *  FROM comprobatetmp;
            IF FOUND THEN
                     -- RAISE NOTICE 'far_actualizarstock  ';
                     elidmovimientostock = rcomprobante.idmovimientostock;
                     RAISE NOTICE 'elidmovimientostock - id  % %',elidmovimientostock,rcomprobante;
                     -- Verifico si el movimiento se genero a partir de un comprobante "Remito"
                     -- calve => idremito

                     IF rcomprobante.nombretabla = 'far_remito' THEN
                        SELECT  into resp far_actualizarstockremito(elidmovimientostock,rcomprobante.id);
                     END IF;

                     IF rcomprobante.nombretabla = 'facturaventa' THEN
                        SELECT into resp far_actualizarstockfacturaventa(elidmovimientostock,rcomprobante.id);
                     END IF;

                     IF rcomprobante.nombretabla = 'far_stockajuste' THEN
                        SELECT into resp far_actualizarstockajuste(elidmovimientostock,rcomprobante.id);
                   END IF;

                   IF rcomprobante.nombretabla = 'far_ordenventa' THEN
                        SELECT into resp far_actualizarstockordenventa(elidmovimientostock,rcomprobante.id);

                   END IF;
                 DROP TABLE movimientostockitemtmp;
            END IF;

     FETCH cmovimientostock into rmovimientostock;
     END LOOP;
     close cmovimientostock;

  RETURN true;
END;

$function$
