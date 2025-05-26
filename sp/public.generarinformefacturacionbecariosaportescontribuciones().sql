CREATE OR REPLACE FUNCTION public.generarinformefacturacionbecariosaportescontribuciones()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       regitem RECORD;
       reginfo RECORD;
       regaporteret RECORD;
       regbecaporte RECORD;
       elem RECORD;
       regtempitem RECORD;
       regaportecta RECORD;
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
 
    cursoraportecta refcursor;
    cursoritem refcursor;
    cursorbecaporte CURSOR FOR SELECT DISTINCT aporte.idaporte, aporte.idcentroregionaluso
                                   FROM concepto JOIN aporte USING(idlaboral, mes, ano, nroliquidacion)
                                   LEFT JOIN informefacturacionbecariosaportescontribuciones USING(idaporte,idcentroregionaluso)
                                   WHERE (concepto.idconcepto= 99311 OR concepto.idconcepto= 99911) 
                                   AND (nullvalue(informefacturacionbecariosaportescontribuciones.idaporte) and nullvalue(informefacturacionbecariosaportescontribuciones.idcentroregionaluso))
                                   GROUP BY aporte.idaporte, aporte.idcentroregionaluso;

 BEGIN
 -- Creo los item del informe de facturacion,
 -- para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
 CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

 --busco si existe algun informe de aportes y contribuciones y que NO haya sido facturado
 SELECT INTO reginfo *  FROM informefacturacionbecariosaportescontribuciones
 NATURAL JOIN (SELECT max(idinformefacturacionestadotipo)  as  idinformefacturacionestadotipo,nroinforme, idcentroinformefacturacion
               FROM informefacturacionestado
               GROUP BY nroinforme, idcentroinformefacturacion) as tempestadoinfo
 WHERE tempestadoinfo.idinformefacturacionestadotipo =3;

  IF NOT FOUND THEN      --me fijo cual es el estado,
                     --si es 3 (facturable) updateo los importes e inserto nuevos items si el nrocuentac no tiene un item ya,
                     --si es 4 o mas (ya se facturo o pago), y no se hace nada

    /*creo el informe de facturacion, 10 es el numero que corresponde al tipo de informe de Aportes y Retribuciones UNC de becarios
           (ver tabla informefacturaciontipo)
            le modifico el estado FACTURABLE*/
            SELECT INTO idinforme * FROM crearinformefacturacion('8',500,10);

            -- Actualizo el Informe para que sea Factura
            UPDATE informefacturacion SET idtipofactura = 'FA'
/*,idformapagotipos=2*/
                   WHERE informefacturacion.nroinforme = idinforme
                   AND informefacturacion.idcentroinformefacturacion = centro();
            -- Cambio el estado del informe de facturacion 3=facturable

            FOR indiceestado IN 1..3 LOOP
                SELECT INTO resp *
                FROM cambiarestadoinformefacturacion(idinforme,centro(),indiceestado,'Generado Automaticamente desde generarinformefacturacionbecariosaportescontribuciones');
             END LOOP;

  ELSE
        IF (reginfo.idinformefacturacionestadotipo=3) THEN
            idinforme =reginfo.nroinforme;
        END IF;
  
  END IF;


 OPEN cursorbecaporte;
 FETCH cursorbecaporte INTO regbecaporte;
             WHILE FOUND LOOP
                    INSERT INTO informefacturacionbecariosaportescontribuciones(nroinforme,idcentroinformefacturacion,idaporte,idcentroregionaluso)
                    VALUES(idinforme,centro(),regbecaporte.idaporte,regbecaporte.idcentroregionaluso);
             FETCH cursorbecaporte INTO regbecaporte;
             END LOOP;
 CLOSE cursorbecaporte;

OPEN cursoraportecta FOR SELECT sum(concepto.importe) as importe,mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta
                         FROM cuentascontables  NATURAL JOIN  mapeocuentascontablesconcepto JOIN
                         concepto ON(mapeocuentascontablesconcepto.nroconcepto=concepto.idconcepto)
                         JOIN aporte USING(idlaboral,nroliquidacion) JOIN afilibec USING(idresolbe)
                         JOIN informefacturacionbecariosaportescontribuciones
                         ON(aporte.idaporte=informefacturacionbecariosaportescontribuciones.idaporte
                         AND aporte.idcentroregionaluso=informefacturacionbecariosaportescontribuciones.idcentroregionaluso)
                         WHERE  (concepto.idconcepto= 99311 OR concepto.idconcepto=99911)
                         AND informefacturacionbecariosaportescontribuciones.idcentroregionaluso=centro()
                         AND informefacturacionbecariosaportescontribuciones.nroinforme=idinforme
                         GROUP BY concepto.idconcepto,mapeocuentascontablesconcepto.nrocuentac,cuentascontables.desccuenta;


FETCH cursoraportecta INTO regaportecta;
WHILE FOUND LOOP
           existeitem = false;
           OPEN cursoritem FOR SELECT DISTINCT informefacturacionitem.*
           FROM informefacturacionitem
           WHERE nroinforme=idinforme AND idcentroinformefacturacion=reginfo.idcentroinformefacturacion;
           FETCH cursoritem INTO regitem;
           WHILE FOUND LOOP
                 IF (regitem.nrocuentac = regaportecta.nrocuentac) THEN
                        UPDATE informefacturacionitem SET importe = regaportecta.importe
                        WHERE informefacturacionitem.nroinforme = idinforme
                        AND informefacturacionitem.idcentroinformefacturacion=reginfo.idcentroinformefacturacion
                        AND nrocuentac=regaportecta.nrocuentac;
                        existeitem= true;
                  END IF;
           FETCH cursoritem INTO regitem;
           END LOOP;
           CLOSE cursoritem;
           IF NOT(existeitem) THEN
           SELECT INTO regtempitem * FROM ttinformefacturacionitem WHERE nrocuentac = regaportecta.nrocuentac;
           IF FOUND THEN
                   UPDATE ttinformefacturacionitem SET importe = regaportecta.importe
                   WHERE ttinformefacturacionitem.nroinforme = idinforme AND nrocuentac=regaportecta.nrocuentac;
           ELSE
                   INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                   VALUES (idinforme,regaportecta.nrocuentac,1,regaportecta.importe,regaportecta.desccuenta);
           END IF;
           END IF;


  FETCH cursoraportecta INTO regaportecta;
  END LOOP;
  CLOSE cursoraportecta;

            



  SELECT INTO resultado * FROM insertarinformefacturacionitem();

/*  SELECT INTO elem sum(informefacturacionitem.importe) as importeinfo, osreci.abreviatura
  FROM informefacturacionitem NATURAL JOIN informefacturacion JOIN osreci ON(informefacturacion.nrocliente=osreci.idosreci AND informefacturacion.barra=osreci.barra)
  WHERE informefacturacion.nroinforme=idinforme AND informefacturacion.idcentroinformefacturacion=centro()
  GROUP BY osreci.abreviatura;

  comprobantemovimiento = idinforme * 100 +centro();
--busco si ya existe una deuda para ese informe

  SELECT INTO recdeuda * FROM cuentacorrientedeuda WHERE cuentacorrientedeuda.idcomprobante = comprobantemovimiento
                                   AND cuentacorrientedeuda.idcomprobantetipos = 21;

  IF FOUND THEN
           UPDATE cuentacorrientedeuda SET saldo =  round(CAST (elem.importeinfo AS numeric), 2), importe =  round(CAST (elem.importeinfo AS numeric), 2)
            WHERE cuentacorrientedeuda.iddeuda = recdeuda.iddeuda AND cuentacorrientedeuda.idcentrodeuda = recdeuda.idcentrodeuda;
	

  ELSE
      nrocuentacontable  = '10302'; ---	Créd.por Ap.y Cont.UNC
      movimientoconcepto = concat('Deuda por generacion de informe numero: ', idinforme , ' - ' , centro());

      INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
	  VALUES (21,500,'U.N.C.',now(),movimientoconcepto,nrocuentacontable,elem.importeinfo,idinforme * 100 +centro(),elem.importeinfo,998,elem.abreviatura);
  END IF;
*/
return resultado;
END;
$function$
