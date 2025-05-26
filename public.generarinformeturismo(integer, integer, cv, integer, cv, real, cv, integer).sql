CREATE OR REPLACE FUNCTION public.generarinformeturismo(integer, integer, character varying, integer, character varying, real, character varying, integer)
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
	formapago integer;
BEGIN
     nrocuentacontablecuota = '40471'; --------visto con Cristian 23/04/10
     nrocuentacontableintereses = '40605'; --------visto con Cristian 23/04/10--

     IF tipofactura = 'FA' THEN -- Es el caso normal, en el que se va generar el consumo de turismo, corresponde facturar
     formapago = 3; -- Corresponde a la forma de pago cta cte
     -- Creo el informe de facturacion y los estados
     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
     --
     -- Inserto informacion propia del informe facturacion turismo
     -- Creo los item del informe de facturacion
     ---
     CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
     INSERT INTO ttinformefacturacionitem (	nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
     VALUES (informeF,nrocuentacontablecuota,1,importetotal,'Valor prestamo turismo');

     SELECT INTO interescuota round (cast((SUM(importe)) as numeric),2) as importeinteres
     FROM (
          SELECT (prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota) as idcomprobante
          FROM     consumoturismo
          NATURAL JOIN prestamo
          NATURAL JOIN prestamocuotas
          WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo and nullvalue(pcborrado)
          ) as TEMP
     JOIN cuentacorrientedeuda USING (idcomprobante)
     WHERE movconcepto ilike '%Interes de Cuota%';
     IF FOUND AND not nullvalue(interescuota.importeinteres) THEN
              impinteres = interescuota.importeinteres;
                --Se registra los intereses omo item de la factura
              INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
              VALUES (informeF,nrocuentacontableintereses,1,impinteres,'Intereses');
     END IF;
     SELECT INTO resp * FROM insertarinformefacturacionitem();
     ELSE -- No es tipo de factura 'FA'
               IF tipofactura = 'NC' THEN -- Necesito generar el informe de una anulacion de turismo

                     CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad
                       INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

                  IF devolveranticipo = 1 THEN -- Hay que generar una NC en cta cte para que le quede a favor
                     formapago = 3; -- VIIIIVIVIVIVIVIVIIVIV 3 Corresponde a la forma de pago cta cte
                     -- Creo el informe de facturacion y los estados
                     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,
                                            barra,tipofactura,formapago);
                     -- Creo los item del informe de facturacion
                     SELECT INTO ranticipo cuentacorrientedeuda.*
                                           FROM   consumoturismo
                                           NATURAL JOIN prestamo
                                           NATURAL JOIN prestamocuotas
                                           JOIN cuentacorrientedeuda
                                                ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                                AND cuentacorrientedeuda.idcomprobantetipos = 7
                                           WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                                                   AND movconcepto ilike '%Anticipo%' and nullvalue(pcborrado) ;

                      IF FOUND THEN
                          DELETE FROM ttinformefacturacionitem;
                         --Se registra los intereses omo item de la factura
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontablecuota,1,ranticipo.importe,concat('Anulacion de Turismo ' , ranticipo.movconcepto));
                      END IF;
                          SELECT INTO resp * FROM insertarinformefacturacionitem();
                  END IF; -- Se devuelve el anticipo
                  -- Generamos la NC por lo que resta pagar
                     formapago = 3; -- Corresponde a la forma de pago cta cte
                     -- Creo el informe de facturacion y los estados
                     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
                     DELETE FROM ttinformefacturacionitem;

                     -- Creo los item del informe de facturacion
                     SELECT INTO impinteres  sum(cuentacorrientedeuda.saldo)
                                           FROM   consumoturismo
                                           NATURAL JOIN prestamo
                                           NATURAL JOIN prestamocuotas
                                           JOIN cuentacorrientedeuda
                                                ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                                AND cuentacorrientedeuda.idcomprobantetipos = 7
                                           WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                                                   AND  cuentacorrientedeuda.saldo > 0 AND cuentacorrientedeuda.movconcepto ilike '%Interes de Cuota%' and nullvalue(pcborrado);

                      IF FOUND AND NOT nullvalue(impinteres) THEN
                         --Se registra los intereses omo item de la factura
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontableintereses,1,impinteres,'Anulacion de Turismo - Intereses');
                      END IF;


                     SELECT INTO impcuotas  sum(cuentacorrientedeuda.saldo)
                                           FROM   consumoturismo
                                           NATURAL JOIN prestamo
                                           NATURAL JOIN prestamocuotas
                                           JOIN cuentacorrientedeuda
                                           ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                            AND cuentacorrientedeuda.idcomprobantetipos = 7
                                             WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                                                   AND  cuentacorrientedeuda.saldo > 0
                                                   AND movconcepto ilike '%Cuota Nº%'
                                                   AND movconcepto not ilike '%Interes de%'and nullvalue(pcborrado);

                      IF FOUND AND NOT nullvalue(impcuotas)THEN
                         --Se registra los intereses el item para el consumo
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontablecuota,1,impcuotas,'Anulacion de Turismo - Costo Consumo');
                      END IF;
                          SELECT INTO resp * FROM insertarinformefacturacionitem();
                      -- Generamos el informe para la devolucion delpago en efecto
                      formapago = 2; -- Corresponde a la forma de pago efectivo

                     -- Creo el informe de facturacion y los estados
                     SELECT INTO informeF * FROM generarinformeturismointerno(codconsumoturismo,centroconsumoturismo,nrodoc,barra,tipofactura,formapago);
                     DELETE FROM ttinformefacturacionitem;

                     -- Creo los item del informe de facturacion
                     SELECT INTO impinteres  sum(cuentacorrientedeuda.importe)
                                           FROM   consumoturismo
                                           NATURAL JOIN prestamo
                                           NATURAL JOIN prestamocuotas
                                           JOIN cuentacorrientedeuda
                                           ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                            AND cuentacorrientedeuda.idcomprobantetipos = 7
                                             WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                                                   AND  cuentacorrientedeuda.saldo = 0 AND cuentacorrientedeuda.movconcepto ilike '%Interes de Cuota%'and nullvalue(pcborrado);

                      IF FOUND and not nullvalue(impinteres) THEN
                         --Se registra los intereses omo item de la factura
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontableintereses,1,impinteres,'Anulacion de Turismo - Intereses');
                      END IF;


                     SELECT INTO impcuotas  sum(cuentacorrientedeuda.importe)
                                           FROM   consumoturismo
                                           NATURAL JOIN prestamo
                                           NATURAL JOIN prestamocuotas
                                           JOIN cuentacorrientedeuda
                                                ON prestamocuotas.idprestamocuotas*10 + prestamocuotas.idcentroprestamocuota = cuentacorrientedeuda.idcomprobante
                                                AND cuentacorrientedeuda.idcomprobantetipos = 7
                                             WHERE idconsumoturismo= codconsumoturismo and idcentroconsumoturismo=centroconsumoturismo
                                                   AND  cuentacorrientedeuda.saldo = 0
                                                   AND movconcepto ilike '%Cuota Nº%'
                                                   AND movconcepto not ilike '%Interes de%'and nullvalue(pcborrado);

                      IF FOUND and not nullvalue(impcuotas)  THEN
                         --Se registra el item para el consumo
                         INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
                         VALUES (informeF,nrocuentacontablecuota,1,impcuotas,'Anulacion de Turismo - Costo Consumo');
                      END IF;
                          SELECT INTO resp * FROM insertarinformefacturacionitem();



               END IF;
     END IF;

return 'true';
END;
$function$
