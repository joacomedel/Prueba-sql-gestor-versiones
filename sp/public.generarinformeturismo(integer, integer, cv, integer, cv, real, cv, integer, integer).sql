CREATE OR REPLACE FUNCTION public.generarinformeturismo(integer, integer, character varying, integer, character varying, real, character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Se crea una nueva instancia de informefacturacion
 * PARAMETROS $1 idconsumoturismo
 *            $2 idcentroconsumoturismo
 *            $3 nrodoc
 *            $4 barra
 *            $5 numero cuenta contable
 *            $6 importeTotal
 *            $7 tipo de factura
 *            $8 si se va a devolver el anticipo
              $9 forma de pago
*/

DECLARE
    codconsumoturismo alias for $1;
    centroconsumoturismo alias for $2;
    nrodoc alias for $3;
    barra  alias for $4;
    numerocuentac alias for $5;
    importetotal alias for $6;
    tipofactura alias for $7; --Parametro que marca el tipo de Comprobante para el que se genera el Informe (FA,ND,NC)
    devolveranticipo alias for $8; -- Se marca si se va a devolver o no el anticipo en la anulacion

    informeF  integer;
    resp boolean;
    nrocuentacontablecuota varchar;
    nrocuentacontableintereses varchar;
    impinteres double precision;
    impcuotas double precision;
    interescuota record;
    ranticipo record;
    reginforme record;
    formapagop alias for $9; -- Parametro que determina la forma de pago del consumo turismo
    formapago integer;
BEGIN
     nrocuentacontablecuota = '40471'; --------visto con Cristian 23/04/10
     nrocuentacontableintereses = '40605'; --------visto con Cristian 23/04/10--
     formapago = formapagop;
     IF tipofactura = 'FA' THEN -- Es el caso normal, en el que se va generar el consumo de turismo, corresponde facturar

          -- Creo el informe de facturacion y los estados
               SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
          --
          -- Inserto informacion propia del informe facturacion turismo
          -- Creo los item del informe de facturacion
          ---
          CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
          INSERT INTO ttinformefacturacionitem (    nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
          VALUES (informeF,nrocuentacontablecuota,1,importetotal,'Consumo turismo');
 
          --  VALUES (informeF,nrocuentacontablecuota,1,importetotal,concat('Consumo turismo Prestamo ',TEMP.idprestamo));
 
           SELECT INTO interescuota round (cast((SUM(importe)) as numeric),2) as importeinteres,idprestamo
           FROM (
                SELECT (prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota) as idcomprobante
                 FROM     consumoturismo
                  NATURAL JOIN prestamo
                   NATURAL JOIN prestamocuotas
                    WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
          ) as TEMP
          JOIN cuentacorrientedeuda USING (idcomprobante)
          WHERE movconcepto ilike '%Interes de Cuota%';
          IF FOUND AND not nullvalue(interescuota.importeinteres) THEN
                    impinteres = interescuota.importeinteres;
                        --Se registra los intereses omo item de la factura
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                          VALUES (informeF,nrocuentacontableintereses,1,impinteres,'Intereses');
  --  VALUES (informeF,nrocuentacontableintereses,1,impinteres,concat('Intereses Prestamo ',interescuota.idprestamo));
                          END IF;
            SELECT INTO resp * FROM insertarinformefacturacionitem();
     ELSE -- No es tipo de factura 'FA'
               IF tipofactura = 'NC' THEN -- Necesito generar el informe de una anulacion de turismo

               SELECT INTO resp * FROM anularconsumoturismoinformacioninformes(codconsumoturismo,centroconsumoturismo,devolveranticipo);
               
               SELECT INTO reginforme * FROM ttanulacionturismoinforme;
               
               CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion

VARCHAR);

                  IF devolveranticipo = 1 THEN -- Hay que generar una NC en cta cte para que le quede a favor
                     formapago = 2; -- Corresponde a la forma de pago efectivo
                     -- Creo el informe de facturacion y los estados
                      IF(reginforme.importeanticipo > 0) THEN
                     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
                     -- Creo los item del informe de facturacion
                     DELETE FROM ttinformefacturacionitem;
                     --Se registra los intereses omo item de la factura
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontablecuota,1,reginforme.importeanticipo,reginforme.movconceptoanticipo);
                     SELECT INTO resp * FROM insertarinformefacturacionitem();
                      END IF;
                  END IF; -- Se devuelve el anticipo
                  -- Generamos la NC por lo que resta pagar
                     IF(reginforme.importerestante > 0) THEN
                     formapago = 3; -- Corresponde a la forma de pago cta cte
                     -- Creo el informe de facturacion y los estados
                     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
                     DELETE FROM ttinformefacturacionitem;
                     -- Creo los item del informe de facturacion
                      IF(reginforme.importeintereses > 0) THEN
                           INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                           VALUES (informeF,nrocuentacontableintereses,1,reginforme.importeintereses,reginforme.movconceptointereses);
                      END IF;
                     --Se registra los intereses el item para el consumo
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontablecuota,1,reginforme.importerestante,reginforme.movconceptorestante);
                         SELECT INTO resp * FROM insertarinformefacturacionitem();
                      END IF;
                          
                      IF (reginforme.importepagado > 0) THEN 
                      -- Generamos el informe para la devolución en efectivo de lo pagado
                      formapago = 2; -- Corresponde a la forma de pago efectivo
                     -- Creo el informe de facturacion y los estados
                     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
                     DELETE FROM ttinformefacturacionitem;
                     -- Creo los item del informe de facturacion
                     --Se registra los intereses omo item de la factura
                     INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                     VALUES (informeF,nrocuentacontablecuota,1,reginforme.importepagado,reginforme.movconceptopagado);
                      
                      IF (reginforme.importeinteresespagado > 0)  THEN
                         --Se registra el item para el consumo
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontablecuota,1,reginforme.importeinteresespagado,reginforme.movconceptointeresespagado);
                      END IF;
                          SELECT INTO resp * FROM insertarinformefacturacionitem();
                      END IF; -- Fin del informe para el importe pagado


               END IF;
     END IF;

return 'true';
END;
$function$
