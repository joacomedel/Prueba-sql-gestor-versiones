CREATE OR REPLACE FUNCTION public.guardardocumentoitem()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
cursordctoitem CURSOR FOR SELECT * FROM tempdocumentoitem;
dctoitem refcursor;

--REGISTRO
regdctoitem RECORD;
regitem RECORD;
BEGIN


open cursordctoitem;   
FETCH cursordctoitem INTO regdctoitem;
   WHILE FOUND LOOP
         OPEN dctoitem FOR SELECT nroordenpago,idcentroordenpago,  importetotal, fechaingreso, nroregistro, anio, idcentrofactura  as idcentroregional, idtipocomprobante,
                                         fimportepagar,    pdescripcion 
                           FROM ordenpago 
                           NATURAL JOIN factura NATURAL JOIN prestador 
                           WHERE factura.nroordenpago=regdctoitem.nroordenpago AND factura.idcentroordenpago = regdctoitem.idcentroordenpago
                           UNION 
                           SELECT nroordenpago, idcentroordenpago, importetotal, fechaingreso,
                           nroreintegro, anio,idcentroregional, 0 as idtipocomprobante, rimporte,concat(apellido ,', ',nombres) as pdescripcion
                           FROM ordenpago NATURAL JOIN reintegro NATURAL JOIN persona 
                           WHERE reintegro.nroordenpago=regdctoitem.nroordenpago AND reintegro.idcentroordenpago = regdctoitem.idcentroordenpago

                           UNION 
                           SELECT    nroordenpago, idcentroordenpago, importetotal, fechaingreso,                         idpresupuesto, idcentropresupuesto,idcentropresupuesto as idcentroregional, 8 as idtipocomprobante, ctopimportepagado,pdescripcion  
                           FROM ordenpago NATURAL JOIN presupuestoitemordenpago NATURAL JOIN presupuestoitem NATURAL JOIN presupuesto  
                           NATURAL JOIN prestador
         --JOIN paseinfodocumento USING(idsolicitudpresupuesto, idcentrosolicitudpresupuesto)  JOIN pase USING(idpase, idcentropase)  
                            WHERE presupuestoitemordenpago.nroordenpago=regdctoitem.nroordenpago  AND presupuestoitemordenpago.idcentroordenpago= regdctoitem.idcentroordenpago

                           ORDER BY nroordenpago;   
                          

          FETCH dctoitem INTO regitem;
          WHILE FOUND LOOP
            
                     INSERT INTO documentoitem(iddocumento,
                                          idcentrodocumento,
                                          idclave,
                                          idcentroclave, 
                                          idanioclave,
                                          idtipocomprobante,
                                          nroordenpago,
                                          idcentroordenpago)
                            VALUES (regdctoitem.iddocumento, regdctoitem.centrodoc, regitem.nroregistro,regitem.idcentroregional,regitem.anio,
                            regitem.idtipocomprobante,regitem.nroordenpago,regitem.idcentroordenpago);
           
          
            FETCH dctoitem INTO regitem;
          END LOOP;

        CLOSE dctoitem;

      FETCH cursordctoitem INTO regdctoitem;
      END LOOP;
CLOSE cursordctoitem;


return true;
END;$function$
