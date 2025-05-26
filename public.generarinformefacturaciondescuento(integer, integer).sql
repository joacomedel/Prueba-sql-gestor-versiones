CREATE OR REPLACE FUNCTION public.generarinformefacturaciondescuento(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       regitem RECORD;
       reginfo RECORD;
       regaporteret RECORD;
       elem RECORD;
       regtempitem RECORD;
       recdeuda RECORD;
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
        cursoritem refcursor;
        cursoraporteret CURSOR FOR SELECT DISTINCT sum(importe) as importe,dh21.nroconcepto,dh21.mesingreso, dh21.anioingreso, mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta
                                   FROM dh21 NATURAL JOIN mapeocuentascontablesconcepto NATURAL JOIN cuentascontables
                                   WHERE (dh21.nroconcepto = 387 OR dh21.nroconcepto = 372)-- AND dh21.nroconcepto = XXX and dh21.nroconcepto = YYY
                                   AND dh21.mesingreso = $1 AND dh21.anioingreso= $2
                                   Group by dh21.nroconcepto,dh21.mesingreso, dh21.anioingreso,mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta;

BEGIN
-- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

--busco si existe algun informe de aportes y contribuciones y que NO haya sido facturado
  SELECT INTO reginfo *
  FROM informefacturaciondescuento
	 NATURAL JOIN (SELECT max(idinformefacturacionestadotipo)  as  idinformefacturacionestadotipo,nroinforme, idcentroinformefacturacion
          FROM informefacturacionestado GROUP BY nroinforme, idcentroinformefacturacion) as tempestadoinfo
  WHERE informefacturaciondescuento.mesingreso = $1 AND informefacturaciondescuento.anioingreso=$2
  AND tempestadoinfo.idinformefacturacionestadotipo >=3;

  IF FOUND THEN--me fijo cual es el estado, si es 3 (facturable) updateo los importes e inserto nuevos items si el nrocuentac no tiene un item ya,
                    --si es 4 o mas (ya se facturo o pago), y no se hace nada
  IF (reginfo.idinformefacturacionestadotipo=3) THEN
  OPEN cursoraporteret;
  FETCH cursoraporteret INTO regaporteret;
  WHILE FOUND LOOP
      idinforme =reginfo.nroinforme;
      existeitem = false;
      OPEN cursoritem FOR SELECT DISTINCT informefacturacionitem.*
      FROM informefacturacionitem
      WHERE nroinforme=reginfo.nroinforme and idcentroinformefacturacion=reginfo.idcentroinformefacturacion;
      FETCH cursoritem INTO regitem;
      WHILE FOUND LOOP

         IF (regitem.nrocuentac = regaporteret.nrocuentac) THEN

             UPDATE informefacturacionitem SET importe = (informefacturacionitem.importe +regaporteret.importe)
             WHERE informefacturacionitem.nroinforme = reginfo.nroinforme AND informefacturacionitem.idcentroinformefacturacion=reginfo.idcentroinformefacturacion
             AND nrocuentac=regaporteret.nrocuentac;
             existeitem= true;
         END IF;

        FETCH cursoritem INTO regitem;
     END LOOP;
     CLOSE cursoritem;
     IF NOT(existeitem) THEN
           SELECT INTO regtempitem * FROM ttinformefacturacionitem WHERE nrocuentac = regaporteret.nrocuentac;
           IF FOUND THEN
             UPDATE ttinformefacturacionitem SET importe = (ttinformefacturacionitem.importe +regaporteret.importe)
             WHERE ttinformefacturacionitem.nroinforme = idinforme AND nrocuentac=regaporteret.nrocuentac;
           ELSE
              INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
              VALUES (reginfo.nroinforme,regaporteret.nrocuentac,1,regaporteret.importe,regaporteret.desccuenta);

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
    SELECT INTO idinforme * FROM crearinformefacturacion('8',500,9);

  -- Actualizo el Informe para que sea Factura
   UPDATE informefacturacion SET idtipofactura = 'FA'
   WHERE informefacturacion.nroinforme = idinforme
   AND informefacturacion.idcentroinformefacturacion = centro();
  -- Cambio el estado del informe de facturacion 3=facturable

     FOR indiceestado IN 1..4 LOOP

          SELECT INTO resp * FROM cambiarestadoinformefacturacion(idinforme,centro(),indiceestado,'Generado Automaticamente desde generarinformefacturaciondescuento');

      END LOOP;



       /*creo el informe de facturacion de DESCUENTOS */
    INSERT INTO informefacturaciondescuento(nroinforme,idcentroinformefacturacion,mesingreso,
                anioingreso)
    VALUES(idinforme,centro(),$1,$2);

   -- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
 OPEN cursoraporteret;
  FETCH cursoraporteret INTO regaporteret;
  WHILE FOUND LOOP
     SELECT INTO regtempitem * FROM ttinformefacturacionitem WHERE nrocuentac = regaporteret.nrocuentac;
     IF FOUND THEN
             UPDATE ttinformefacturacionitem SET importe = (ttinformefacturacionitem.importe +regaporteret.importe)
             WHERE ttinformefacturacionitem.nroinforme = idinforme AND nrocuentac=regaporteret.nrocuentac;

     ELSE
              INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
              VALUES (idinforme,regaporteret.nrocuentac,1,regaporteret.importe,regaporteret.desccuenta);
     END IF;
     FETCH cursoraporteret INTO regaporteret;
  END LOOP;
  CLOSE cursoraporteret;

  END IF;


  SELECT INTO resultado * FROM insertarinformefacturacionitem();



  SELECT INTO elem sum(informefacturacionitem.importe) as importeinfo, osreci.abreviatura
  FROM informefacturacionitem NATURAL JOIN informefacturacion JOIN osreci ON(informefacturacion.nrocliente=osreci.idosreci AND informefacturacion.barra=osreci.barra)
  WHERE informefacturacion.nroinforme=idinforme AND informefacturacion.idcentroinformefacturacion=centro()
  GROUP BY osreci.abreviatura;

  comprobantemovimiento = idinforme * 100 +centro();
--busco si ya existe una deuda para ese informe


  SELECT INTO recdeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobante = comprobantemovimiento
                                   AND cuentacorrientedeuda.idcomprobantetipos = 999;

  IF FOUND THEN
           UPDATE cuentacorrientedeuda SET saldo =  round(CAST (elem.importeinfo AS numeric), 2), importe =  round(CAST (elem.importeinfo AS numeric), 2)
            WHERE cuentacorrientedeuda.iddeuda = recdeuda.iddeuda AND cuentacorrientedeuda.idcentrodeuda = recdeuda.idcentrodeuda;
	

 ELSE

  nrocuentacontable  = '9999'; --	Créd.por Descuentos UNC
  movimientoconcepto = concat('Deuda por generacion de informe numero: ' , idinforme , ' - ' , centro());




    INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
	VALUES (999,500,elem.abreviatura,now(),movimientoconcepto,nrocuentacontable,elem.importeinfo,idinforme * 100 +centro(),elem.importeinfo,998,elem.abreviatura);
 
 END IF;




return resultado;
END;
$function$
