CREATE OR REPLACE FUNCTION public.asentarimputacionmanualctacteconsaldoafavor()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*/
DECLARE
       curmovimientos refcursor;
       unmovimiento RECORD;
       rafavor RECORD;
       rctacteafavor RECORD;
       unmov RECORD;
       importerestante double precision;
       importesinpagar double precision;
       importeimputado double precision;
       inimovconceptocancelacion varchar;
       ultimomovimiento bigint;
       fechamov timestamp;

BEGIN
SELECT INTO rafavor * FROM tempimputacion WHERE tempimputacion.movcancela;
SELECT INTO rctacteafavor * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = rafavor.idmovcancela;

importerestante = rctacteafavor.importe;
OPEN curmovimientos FOR SELECT *
                          FROM tempimputacion
                          WHERE NOT tempimputacion.movcancela
                          ORDER BY tempimputacion.idmovimiento;

FETCH curmovimientos INTO unmov;
WHILE  found LOOP
SELECT INTO unmovimiento * FROM cuentacorriente WHERE cuentacorriente.idmovimiento = unmov.idmovimiento;
/*Se va a cancelar un movimiento completo*/
     IF unmovimiento.importe <= importerestante THEN
        UPDATE cuentacorriente SET idmovcancela = rctacteafavor.idmovimiento WHERE cuentacorriente.idmovimiento = unmovimiento.idmovimiento;
     END IF;
/*Se cancela un movimiento parcialmente*/
     IF unmovimiento.importe > importerestante THEN
        importesinpagar = unmovimiento.importe - importerestante;
        --importesinpagar = 100,1;
        inimovconceptocancelacion = 'I.M.P/Parcial-';
        fechamov = CURRENT_TIMESTAMP;
        INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,comprobante)
        VALUES(nextval('cuentacorriente_idmovimiento_seq'),unmovimiento.idcomprobantetipos,unmovimiento.tipodoc,unmovimiento.nrodoc,fechamov,concat(inimovconceptocancelacion , unmovimiento.movconcepto),unmovimiento.nrocuentac,importesinpagar,unmovimiento.signo,unmovimiento.idcomprobante,unmovimiento.idcomprobante);
        UPDATE cuentacorriente SET idmovcancela = rctacteafavor.idmovimiento
                              ,importe = importerestante
                             WHERE cuentacorriente.idmovimiento = unmovimiento.idmovimiento;
     END IF;
importerestante = importerestante - unmovimiento.importe;
ultimomovimiento = unmovimiento.idmovimiento;
FETCH curmovimientos INTO unmov;
END LOOP;
/*Para el caso que el importe a favor es mayor que la suma de los importes imputados*/
IF importerestante > 0 THEN
   importeimputado = rctacteafavor.importe - importerestante;
   inimovconceptocancelacion = 'I.M.P/UsoParcial-';
   fechamov = CURRENT_TIMESTAMP;
   INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,comprobante)
        VALUES(nextval('cuentacorriente_idmovimiento_seq'),rctacteafavor.idcomprobantetipos,rctacteafavor.tipodoc,rctacteafavor.nrodoc,fechamov,concat(inimovconceptocancelacion , rctacteafavor.movconcepto),rctacteafavor.nrocuentac,importerestante,rctacteafavor.signo,rctacteafavor.idcomprobante,rctacteafavor.idcomprobante);
   UPDATE cuentacorriente SET importe = importeimputado
                              ,comprobante = rctacteafavor.comprobante
                             WHERE cuentacorriente.idmovimiento = rctacteafavor.idmovimiento;

END IF;
UPDATE cuentacorriente SET idmovcancela = ultimomovimiento
                           WHERE cuentacorriente.idmovimiento = rctacteafavor.idmovimiento;
close curmovimientos;
RETURN 'true';
END;
$function$
