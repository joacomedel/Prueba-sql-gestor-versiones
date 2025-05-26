CREATE OR REPLACE FUNCTION public.modif_movimiento_mp(character varying)
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
       payerIDNumb varchar;
       concepto varchar;
       rmov record;
       rparam record;

BEGIN

       SELECT INTO elem * 
       FROM temp_MovimientoMP as tmpmp
       WHERE tmpmp.sourceID = $1 AND LENGTH(tmpmp.externalReference)>5;

       extref = elem.externalReference;
       sourceID = elem.sourceID;
       payername = elem.payername;
       payerID = elem.payerID;
       payerIDNumb = elem.payerIDNumb;

       concepto=' ';

              IF POSITION('|' IN elem.externalReference) > 0 THEN
              /* En este caso es un Recibo */
                     /* Busco el movconcepto del movimiento original y lo concateno en el concepto*/
                     SELECT INTO rmov * 
                     FROM ctactedeudacliente 
                     WHERE concat(iddeuda ,'|', idcentrodeuda) = extref;
                                    
                     IF FOUND THEN

                            concepto=concat( ' - ', rmov.movconcepto);
                            
                     END IF;
              
              ELSE

                     IF ( (POSITION('MP-QR' IN elem.externalReference) > 0)) THEN
                     /* En este caso es una Factura */

                            concepto=concat( ' - FAC - Factura - ', payername , ' - ', payerIDNumb);

                     ELSE     
                            -- Si es Venta presencial le concatena Venta presencial 
                            IF ( (POSITION('Venta presencial' IN elem.externalReference) > 0) ) THEN

                                   concepto= ' - Venta presencial';

                            ELSE     
                                   IF  (POSITION('money_transfer' IN elem.externalReference) > 0) THEN
                                   /* Puede llegar a ser una transferencia de dinero hacia la cuenta de MP de SOSUNC */

                                          concepto=concat( ' - Transferencia Bancaria  - ', payername , ' - ', payerIDNumb);


                                   ELSE

                                          /* Si llega acá me queda ver si no está vacío o si es el conjunto de letras y números, en el 2do caso  llegue a la conclusion de que es una transferencia 
                                          Tuve que verificar que la longitud de las letras y numeros fuera mayor a 21 porque suelen ser de 22 por lo que pude contar. Pero hay unos casos de unos 
                                          6 numeros que vienen tambien entonces puse 21 para corroborar esto */

                                                 IF ( elem.externalReference != '0' AND LENGTH(elem.externalReference)>5 )  THEN

                                                        concepto=' - Transferencia Bancaria';

                                                 END IF;

                                   END IF; 

                            END IF; 

                     END IF; 

              END IF; 

return concepto;
END;
$function$
