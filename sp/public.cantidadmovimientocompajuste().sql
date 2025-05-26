CREATE OR REPLACE FUNCTION public.cantidadmovimientocompajuste()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
      ccompajuste refcursor;
       cmov refcursor;
       unmov record ;
      uncomajuste record;
      cant integer;
BEGIN
     --- creo una tabla donde la cantidad de item de un movimiento no coincide con la cantidad
     -- de item de comprobante de ajuste
    /* CREATE TABLE resutltadoanalisiscompajuste (idmovimientostock bigint , idcentromovimientostock integer,
                        idstockajuste bigint,idcentrostockajuste integer,
                        descripcion varchar
                        ) ;*/
      DELETE FROM resutltadoanalisiscompajuste;
   
     -- Primero verifico cuantos item tiene un comprobante de ajuste
     
      OPEN ccompajuste FOR SELECT count(*) as cantitemajuste,idstockajuste,idcentrostockajuste
           FROM far_movimientostockitemstockajuste
           NATURAL JOIN far_stockajusteitem
           NATURAL JOIN far_stockajuste
           WHERE safecha>='2014-12-01'
          
           group by idstockajuste,idcentrostockajuste
           order by idstockajuste,idcentrostockajuste;

     FETCH ccompajuste into uncomajuste;
     WHILE FOUND LOOP
           -- Verifico cuantos movimientos de stock item tiene un comprobante de ajuste
           OPEN cmov FOR  SELECT  count(*) as cantiitemmov,  idmovimientostock,idcentromovimientostock
           FROM far_stockajusteitem
           NATURAL JOIN far_movimientostockitemstockajuste
           NATURAL JOIN far_movimientostockitem
           WHERE idstockajuste = uncomajuste.idstockajuste
                 and idcentrostockajuste = uncomajuste.idcentrostockajuste
           group by idmovimientostock,idcentromovimientostock;
           cant=0;
           FETCH cmov into unmov;
           WHILE FOUND LOOP
                 -- 2 se recorre cada uno de los comprobantes de ajustes encontrados
                  INSERT INTO resutltadoanalisiscompajuste (idmovimientostock  , idcentromovimientostock ,
                        idstockajuste ,idcentrostockajuste ,descripcion ,   cantitemmov , cantitemajus  )VALUES (
                        unmov.idmovimientostock  , unmov.idcentromovimientostock ,
                         uncomajuste.idstockajuste ,uncomajuste.idcentrostockajuste ,concat('cantidad: ',cant) , unmov.cantiitemmov   ,  uncomajuste.cantitemajuste   );
                  cant = cant +1 ;
           FETCH cmov into unmov;
           END LOOP;
            close cmov;
           FETCH ccompajuste into uncomajuste;
     END LOOP;
     close ccompajuste;
     return 'Listo';
END;
$function$
