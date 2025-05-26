CREATE OR REPLACE FUNCTION public.far_articulomoverstock(bigint, integer, integer, integer, date, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    clote refcursor;
    unlote record;
    elidarticulo bigint;
    cantarticulos integer;
    nuevostocklote integer;

    elsigno integer;
    cantlote integer;
    fechavencimiento date;
    codmovitem bigint;
    codlote bigint;
    codmovimientostock bigint;
    cantartrestar bigint;
    ultimolote bigint;
    ultimolotecentro integer;
    haylote record;
    elidcentroarticulo integer;

BEGIN

-- $1 idarticulo
-- $2 idcentroarticulo
-- $3 cantidad
-- $4 signo
--         -1 = decrementar stock  (movimientos stock)
--          1 = incrementar stock   (movimientos stock)
--          0 = nuevo lote
-- $4 fechavencimiento

   elidarticulo = $1;
   elidcentroarticulo  = $2;
   cantarticulos = $3;
   elsigno =$4;
   fechavencimiento = $5;
   codmovimientostock =$6;
   cantartrestar = 0;

   
   -- Se busca el lote del centro regional en el que se esta realizando la operacion
   -- el articulo no necesariamente se trata de un articulo cargado en el centro reg
   SELECT INTO haylote *
   FROM far_lote
   WHERE idcentrolote = centro()
        and idarticulo = elidarticulo and idcentroarticulo = elidcentroarticulo;

   IF (NOT found ) THEN
         elsigno = 0;
   END IF;
    IF (elsigno = 0 ) THEN -- cuando es =0 estamos ingresando un uevo lote
                          --Malapi 02/12/2014 Modifico para que el lote se genere con cantidad inicial en 0, pues no se cuentos elementos tengo. Ademas luego de generado el lote, lo dejo para que siga el procedimiento normal.
           elsigno =$4;
           INSERT INTO far_lote (lfechavencimiento,idarticulo,idcentroarticulo,lstock,lstockinicial)
                  VALUES (fechavencimiento,elidarticulo,elidcentroarticulo,0,0);
          codlote = currval('public.far_lote_idlote_seq');
          --Comento Malapi el 02/12/2014
          --INSERT INTO far_movimientostockitem(idmovimientostock,mscantidad,idlote,idcentrolote,msisigno)
          --                     VALUES(codmovimientostock,cantarticulos,codlote,centro(),elsigno);
          --codmovitem = currval('public.far_movimientostockitem_idmovimientostockitem_seq');
          --INSERT INTO  movimientostockitemtmp(idmovimientostockitem) VALUES (codmovitem);


   END IF;
   -- recupero lotes del centro  del articulo $1 donde la fecha de vencimiento coincide con $3 
   -- los ordeno x fecha de modificacion del lote
          OPEN clote FOR
               SELECT *
               FROM far_articulo
               NATURAL JOIN far_lote
               WHERE idcentrolote = centro()
		     and idarticulo = elidarticulo and idcentroarticulo = elidcentroarticulo
                     and  (nullvalue(fechavencimiento) OR lfechavencimiento =fechavencimiento)

              ORDER BY lfechamofificacion ASC ;

          FETCH clote into unlote;
          WHILE  found and cantarticulos >0 LOOP
                 cantlote = unlote.lstock;
                 cantartrestar = 0;
                 IF (cantlote > cantarticulos or elsigno = 1  ) THEN  -- si el signo es 1 se trata de un incremento en el stock
                         nuevostocklote = cantlote + (elsigno * cantarticulos) ;
                         cantartrestar = cantarticulos;
                         cantarticulos = 0 ;

                 ELSE   --- no es necesario se mantiene para no permitir lotes stock megativo
                         nuevostocklote = cantlote + (elsigno *cantarticulos);

                        -- cantartrestar = cantlote;
                        cantartrestar = cantarticulos;
                           --  cantarticulos = cantarticulos - cantlote;
                         cantarticulos = 0;
                 END IF;
                 /*  Actualizo el stock del lote  */
                 UPDATE far_lote
                 SET lstock = nuevostocklote , lfechamofificacion=NOW()
                 WHERE idlote = unlote.idlote and idcentrolote =unlote.idcentrolote ;

                 -- mscantidad contiene el stock con el que quedo el lote luego del movimiento
                 INSERT INTO far_movimientostockitem (idmovimientostock,msistockposterior ,mscantidad, msistockanterior,idlote,idcentrolote,msisigno)
                               VALUES(codmovimientostock,nuevostocklote,cantartrestar,cantlote,unlote.idlote,unlote.idcentrolote,elsigno);
                 codmovitem = currval('public.far_movimientostockitem_idmovimientostockitem_seq');
                 INSERT INTO  movimientostockitemtmp(idmovimientostockitem) VALUES (codmovitem);
                 ultimolote = unlote.idlote;
		 ultimolotecentro =   unlote.idcentrolote;
                 fetch clote into unlote;
          END LOOP;
          close clote;
          -- Si quedaron articulos que no pudieron vincularse a ningun lote se crea un lote nuevo
          IF ( cantarticulos >0 and elsigno = 1  ) THEN
                             INSERT INTO far_lote ( lfechavencimiento,idarticulo,idcentroarticulo,lstock,lstockinicial)
                                    VALUES(fechavencimiento,elidarticulo,elidcentroarticulo , cantarticulos,cantarticulos);
                              codlote = currval('public.far_lote_idlote_seq1');
                              INSERT INTO far_movimientostockitem (idmovimientostock,msistockposterior,mscantidad , msistockanterior,idlote,idcentrolote,msisigno)
                                    VALUES(codmovimientostock,cantarticulos,cantarticulos,cantarticulos,codlote,centro(),elsigno);
                             codmovitem = currval('public.far_movimientostockitem_idmovimientostockitem_seq');
                             INSERT INTO  movimientostockitemtmp(idmovimientostockitem) VALUES (codmovitem);
          ELSE
              if ( cantarticulos >0 and elsigno = -1 )  THEN
                       /*  Actualizo el stock del lote  */
                       UPDATE far_lote SET lstock = (cantarticulos*-1)
                       WHERE idlote = ultimolote and idcentrolote =ultimolotecentro;
                       INSERT INTO far_movimientostockitem (idmovimientostock,msistockposterior,mscantidad , msistockanterior,msisigno)
                                    VALUES(codmovimientostock,88888,999999,0,codlote,elsigno);
                       codmovitem = currval('public.far_movimientostockitem_idmovimientostockitem_seq');
                       INSERT INTO  movimientostockitemtmp(idmovimientostockitem) VALUES (codmovitem);

                END IF;

          END IF;


--END IF; Comento Malapi 02-12-2014
return 'true';
END;
$function$
