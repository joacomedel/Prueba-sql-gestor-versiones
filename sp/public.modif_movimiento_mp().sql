CREATE OR REPLACE FUNCTION public.modif_movimiento_mp()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       elem record;
       cursormovbancomp refcursor;
       movconcepto varchar;
       extref varchar;
       sourceID varchar;
       payername varchar;
       payerID varchar;
       rmov record;

BEGIN

       OPEN cursormovbancomp  FOR   SELECT * FROM temp_MovimientoMP;

       FETCH cursormovbancomp INTO elem;
          
          
       WHILE found LOOP

              extref = elem.externalReference;
              sourceID = elem.sourceID;
              payername = elem.payername;
              payerID = elem.payerID;

              IF POSITION('|' IN elem.externalReference) > 0 THEN
                            -- Busco el movconcepto del movimiento original
                     SELECT INTO rmov * 
                     FROM ctactedeudacliente 
                     WHERE concat(iddeuda ,'|', idcentrodeuda) = extref;
                                    
                     IF FOUND THEN
                            UPDATE bancamovimiento
                            SET bmconcepto = concat( bmconcepto,' - ', rmov.movconcepto)
                            WHERE bmnrocomprobante = sourceID;
                     END IF;
              END IF;

                            -- Si es MP QR o por Venta presencial le concatena el FAC Factura
              IF ( (POSITION('MP-QR' IN elem.externalReference) > 0) OR (POSITION('Venta presencial' IN elem.externalReference) > 0) ) THEN
                            UPDATE bancamovimiento
                            SET bmconcepto = concat( bmconcepto,' - ', 'FAC - Factura',' - ', payerID,' - ', payername)
                            WHERE bmnrocomprobante = sourceID;
              END IF;     

              FETCH cursormovbancomp INTO elem;

       END LOOP;
       CLOSE cursormovbancomp;
       
return 'true';
END;
$function$
