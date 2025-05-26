CREATE OR REPLACE FUNCTION public.generarinformefacturacionaportescontribuciones(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       regitem RECORD;
       regliq RECORD;
       reginfo RECORD;
       regaporteret RECORD;
       elem RECORD;
       regtempitem RECORD;
       recdeuda RECORD;
       recdeudanoafil RECORD;
       refinfo RECORD;

  --VARIABLES
	
        comprobantemovimiento BIGINT;
        movimientoconcepto VARCHAR;
        nrocuentacontable VARCHAR;
        resultado BOOLEAN;
        idinforme integer;
        indiceestado integer;
        importeinfoitem DOUBLE PRECISION;
        resp BOOLEAN;
        existeitem BOOLEAN;

 --CURSORES
        cursorliq refcursor;
        cursorinfo refcursor;
        cursoritem refcursor;
        cursoraporteret CURSOR FOR SELECT DISTINCT sum(importe) as importe,dh21.mesingreso, dh21.anioingreso,dh21.nroliquidacion,mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta
                                   FROM dh21 NATURAL JOIN mapeocuentascontablesconcepto NATURAL JOIN cuentascontables
                                   WHERE dh21.nroconcepto <> 387 and dh21.nroconcepto <> (-51) and dh21.nroconcepto <> 372 AND dh21.nroconcepto <> 911 AND dh21.nroconcepto <> 60 AND (nrocuentac ='40210' OR nrocuentac='40215' OR nrocuentac='40220')
                                    AND dh21.mesingreso = $1 AND dh21.anioingreso= $2
                                  Group by dh21.nroliquidacion,dh21.mesingreso, dh21.anioingreso,mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta
                                    UNION
                                    SELECT DISTINCT sum(importe) as importe,dh21.mesingreso, dh21.anioingreso,dh21.nroliquidacion , mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta
                                   FROM dh21 NATURAL JOIN mapeocuentascontablesconcepto NATURAL JOIN cuentascontables
                                   WHERE dh21.nroconcepto= 911 AND dh21.mesingreso = $1 AND dh21.anioingreso= $2 AND (nrocuentac ='40210' OR nrocuentac='40215' OR nrocuentac='40220')
                                   group by dh21.nroliquidacion,dh21.mesingreso, dh21.anioingreso,mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta;


BEGIN
         -- Creo los item del informe de facturacion,
         -- para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
        CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

   OPEN cursorliq FOR SELECT dh21.nroliquidacion
                      FROM dh21 NATURAL JOIN mapeocuentascontablesconcepto NATURAL JOIN cuentascontables
                      WHERE dh21.nroconcepto <> 387 and dh21.nroconcepto <> (-51) and dh21.nroconcepto <> 372
                      AND dh21.nroconcepto <> 911 AND dh21.nroconcepto <> 60
                      AND dh21.mesingreso = $1 AND dh21.anioingreso= $2 AND
                      (nrocuentac ='40210' OR nrocuentac='40215' OR nrocuentac='40220')
                      Group by dh21.nroliquidacion
                      UNION
                      SELECT dh21.nroliquidacion
                      FROM dh21 NATURAL JOIN mapeocuentascontablesconcepto NATURAL JOIN cuentascontables
                      WHERE dh21.nroconcepto= 911 AND dh21.mesingreso = $1 AND dh21.anioingreso= $2 AND
                      (nrocuentac ='40210' OR nrocuentac='40215' OR nrocuentac='40220')
                      group by dh21.nroliquidacion;
    FETCH cursorliq INTO regliq;
    WHILE FOUND LOOP --mientras haya liquidaciones diferentes, creo un informe

        --busco si existe algun informe de aportes y contribuciones y que NO haya sido facturado
        SELECT INTO reginfo *  FROM informefacturacionaportescontribuciones
	         NATURAL JOIN (SELECT max(idinformefacturacionestadotipo)  as  idinformefacturacionestadotipo,nroinforme, idcentroinformefacturacion
                           FROM informefacturacionestado
                           GROUP BY nroinforme, idcentroinformefacturacion) as tempestadoinfo
                           WHERE informefacturacionaportescontribuciones.mesingreso = $1
                           AND informefacturacionaportescontribuciones.anioingreso=$2
                           AND informefacturacionaportescontribuciones.nroliquidacion=regliq.nroliquidacion
                           AND tempestadoinfo.idinformefacturacionestadotipo >=3;

        IF FOUND THEN      --me fijo cual es el estado,
                          --si es 3 (facturable) updateo los importes e inserto nuevos items si el nrocuentac no tiene un item ya,
                          --si es 4 o mas (ya se facturo o pago), y no se hace nada
                    IF (reginfo.idinformefacturacionestadotipo=3) THEN
                         OPEN cursoraporteret;
                         FETCH cursoraporteret INTO regaporteret;
                         WHILE FOUND LOOP
                          IF regaporteret.nroliquidacion=regliq.nroliquidacion THEN

                               idinforme =reginfo.nroinforme;
                               existeitem = false;
                               OPEN cursoritem FOR SELECT DISTINCT informefacturacionitem.*
                               FROM informefacturacionitem
                               WHERE nroinforme=reginfo.nroinforme and idcentroinformefacturacion=reginfo.idcentroinformefacturacion;
                               FETCH cursoritem INTO regitem;
                               WHILE FOUND LOOP
                                     IF (regitem.nrocuentac = regaporteret.nrocuentac) THEN
                                             UPDATE informefacturacionitem SET importe = regaporteret.importe
                                             WHERE informefacturacionitem.nroinforme = reginfo.nroinforme
                                                   AND informefacturacionitem.idcentroinformefacturacion=reginfo.idcentroinformefacturacion
                                                   AND nrocuentac=regaporteret.nrocuentac;
                                             existeitem= true;
                                     END IF;
                               FETCH cursoritem INTO regitem;
                               END LOOP;
                               CLOSE cursoritem;
                               IF NOT(existeitem) THEN
                                     SELECT INTO regtempitem * FROM ttinformefacturacionitem WHERE nrocuentac = regaporteret.nrocuentac;
                                     IF FOUND THEN
                                              UPDATE ttinformefacturacionitem SET importe = regaporteret.importe
                                              WHERE ttinformefacturacionitem.nroinforme = idinforme AND nrocuentac=regaporteret.nrocuentac;
                                     ELSE
                                              INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                                              VALUES (reginfo.nroinforme,regaporteret.nrocuentac,1,regaporteret.importe,regaporteret.desccuenta);
                                      END IF;
                               END IF;
                        END IF;
                         FETCH cursoraporteret INTO regaporteret;
                         END LOOP;
                         CLOSE cursoraporteret;


                   END IF;
   ELSE

           /*creo el informe de facturacion, 8 es el numero que corresponde al tipo de informe de Aportes y Retribuciones UNC
           (ver tabla informefacturaciontipo)
            le modifico el estado FACTURABLE*/
            SELECT INTO idinforme * FROM crearinformefacturacion('8',500,8);

            -- Actualizo el Informe para que sea Factura
            UPDATE informefacturacion SET idtipofactura = 'FA'
                   WHERE informefacturacion.nroinforme = idinforme
                   AND informefacturacion.idcentroinformefacturacion = centro();
            -- Cambio el estado del informe de facturacion 3=facturable

            FOR indiceestado IN 1..3 LOOP
                SELECT INTO resp *
                FROM cambiarestadoinformefacturacion(idinforme,centro(),indiceestado,'Generado Automaticamente desde generarinformefacturacionaportesretribuciones');
             END LOOP;

             /*creo el informe de facturacion de APORTES Y CONTRIBUCIONES */
             INSERT INTO informefacturacionaportescontribuciones(nroinforme,idcentroinformefacturacion,mesingreso,
                anioingreso,nroliquidacion)VALUES(idinforme,centro(),$1,$2,regliq.nroliquidacion);

             -- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
             OPEN cursoraporteret;
             FETCH cursoraporteret INTO regaporteret;
             WHILE FOUND LOOP
               IF regaporteret.nroliquidacion=regliq.nroliquidacion THEN
                   SELECT INTO regtempitem * FROM ttinformefacturacionitem
                   WHERE nrocuentac = regaporteret.nrocuentac AND nroinforme=idinforme;
                   IF FOUND THEN
                            UPDATE ttinformefacturacionitem SET importe = regaporteret.importe
                                   WHERE ttinformefacturacionitem.nroinforme = idinforme AND nrocuentac=regaporteret.nrocuentac AND regaporteret.nroliquidacion=regliq.nroliquidacion;
                   ELSE
                            INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                                   VALUES (idinforme,regaporteret.nrocuentac,1,regaporteret.importe,regaporteret.desccuenta);
                   END IF;
               END IF;
             FETCH cursoraporteret INTO regaporteret;
             END LOOP;
             CLOSE cursoraporteret;


  END IF;
  FETCH cursorliq INTO regliq;
END LOOP;

 SELECT INTO resultado * FROM insertarinformefacturacionitem();


 OPEN cursorinfo FOR SELECT DISTINCT nroinforme
                     FROM ttinformefacturacionitem;
                              
 FETCH cursorinfo INTO refinfo;
         
 WHILE FOUND LOOP
            PERFORM generardeudaordenesinstitucion(refinfo.nroinforme);



FETCH cursorinfo INTO refinfo;
 
END LOOP;
CLOSE cursorinfo;
return resultado;
END;$function$
