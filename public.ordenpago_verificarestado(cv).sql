CREATE OR REPLACE FUNCTION public.ordenpago_verificarestado(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

    rdata RECORD;
    r_estado_fact RECORD;
    cursor_facturaestado refcursor;
    r_estado_minuta  RECORD;
  

BEGIN
      EXECUTE sys_dar_filtros($1) INTO rdata;
     
      /*Si todas las facturas de la minuta estan autorizadas para el pago la orden de pago debe pasar al estado 6
       * El estado 6 representa la aprobacion del pago total de la minuta
      */
    
      SELECT INTO r_estado_minuta * FROM cambioestadoordenpago
                                    WHERE nullvalue(ceopfechafin)
                                          and idcentroordenpago =  rdata.idcentroordenpago and  nroordenpago = rdata.nroordenpago;
      OPEN cursor_facturaestado  FOR SELECT  tipoestadofactura ,  row_number() over() as numfila
                                     FROM factura
                                     NATURAL JOIN festados
                                     WHERE nullvalue(fefechafin)
                                            and idcentroordenpago =  rdata.idcentroordenpago and  nroordenpago = rdata.nroordenpago

                                     GROUP BY tipoestadofactura
                                     ORDER BY  row_number() over() desc;
      FETCH cursor_facturaestado INTO r_estado_fact;
      IF FOUND THEN
               -- Si agrupando por estado la cantidad de registros retornados es 1 y tipoestadofactura = 6 se verifica que todas las factuas estan autorizadas
                   IF(r_estado_fact.numfila =1 AND r_estado_fact.tipoestadofactura = 6  AND r_estado_minuta.idtipoestadoordenpago <> 6) THEN
                          -- cambio el estado de la minuta a autorizada para el pago = 6
                          PERFORM  cambiarestadoordenpago(rdata.nroordenpago ,  rdata.idcentroordenpago, 6, 'Modif. desde ordenpago_verificarestado ');
                   END IF;
                   IF(r_estado_fact.tipoestadofactura = 3 AND r_estado_minuta.idtipoestadoordenpago <> 3) THEN
                          -- cambio el estado de la minuta a liquidable para el pago = 3
                          PERFORM  cambiarestadoordenpago(rdata.nroordenpago ,  rdata.idcentroordenpago, 3, 'Modif. desde ordenpago_verificarestado ');
                   END IF;
      END IF;
      
RETURN true;
END;
$function$
