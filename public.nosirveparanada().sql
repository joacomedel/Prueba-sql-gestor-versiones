CREATE OR REPLACE FUNCTION public.nosirveparanada()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que asienta los envios a descontar a la universidad de la deuda
en ctacte
*/
DECLARE
       cursormovimientos CURSOR FOR SELECT * FROM eliminadosamanotablaquenosirve
                                    ORDER BY nrodoc;
       unmovimiento RECORD;
       deudaoriginal RECORD;
       uninforme RECORD;
       inimovconceptocancelacion VARCHAR;
       movconceptocancelacion VARCHAR;
       vcomprobanteimputacion BIGINT;
       vcomprobantetipos INTEGER;
       fechamov TIMESTAMP;
       movcancala bigint;
       

BEGIN
     OPEN cursormovimientos;
     FETCH cursormovimientos into unmovimiento;
     WHILE  found LOOP
     SELECT INTO deudaoriginal * FROM cuentacorriente WHERE idmovimiento = unmovimiento.idmovimiento;
     IF FOUND THEN
         --Modifico los movimentos para que figuren como cancelados e imputados
     SELECT INTO uninforme * FROM informedescuentoplanilla
                         WHERE (informedescuentoplanilla.nrodoc)::integer * 10 + informedescuentoplanilla.tipodoc = unmovimiento.nrodoc
                         AND  informedescuentoplanilla.mes = 9 AND informedescuentoplanilla.anio = 2007 ;
         -- El tipo de comprobante vuelve a ser el del consumo original
         inimovconceptocancelacion = 'I.A.P/TotalUNC-R-';
          movconceptocancelacion = concat(inimovconceptocancelacion , deudaoriginal.movconcepto);
       --La fecha del movimiento es la fecha en la que se imputo el envio a descontar
            SELECT INTO fechamov CURRENT_TIMESTAMP;
         --Tengo que marcar como cancelado el movimiento que cancelaba al movimiento original
         --Si es un pago Total tengo que insertar la tupla que cancela el pago de 10311 y modificar el movimiento que lo cancela
                vcomprobantetipos = 11;
                vcomprobanteimputacion = uninforme.idinforme;
                INSERT INTO cuentacorriente(idmovimiento,idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo,idcomprobante,idmovcancela)
                       VALUES(nextval('cuentacorriente_idmovimiento_seq'),vcomprobantetipos,deudaoriginal.tipodoc,deudaoriginal.nrodoc,fechamov,movconceptocancelacion,deudaoriginal.nrocuentac,deudaoriginal.importe,deudaoriginal.signo * -1,vcomprobanteimputacion,deudaoriginal.idmovimiento);
                movcancala =  currval('cuentacorriente_idmovimiento_seq');
                UPDATE cuentacorriente SET idmovcancela = movcancala WHERE cuentacorriente.idmovimiento = unmovimiento.idmovimiento;
     END IF;
     FETCH cursormovimientos into unmovimiento;
     END LOOP;
     close cursormovimientos;
RETURN TRUE;
END;
$function$
