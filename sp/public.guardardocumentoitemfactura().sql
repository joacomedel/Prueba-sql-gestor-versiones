CREATE OR REPLACE FUNCTION public.guardardocumentoitemfactura()
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
             RAISE NOTICE 'regdctoitem(%)',regdctoitem;
                     INSERT INTO documentoitem(iddocumento,
                                          idcentrodocumento,
                                          idclave,
                                          idcentroclave, 
                                          idrecepcion,
                                          idcentroregional, 
                                          idtipocomprobante
                                          )
                                  VALUES (regdctoitem.iddocumento, regdctoitem.centrodoc,regdctoitem.idclave,
                                         regdctoitem.idcentroclave,regdctoitem.idclave,
                                         regdctoitem.idcentroclave,regdctoitem.idtipocomprobante);
           
                 
          
         
      FETCH cursordctoitem INTO regdctoitem;
      END LOOP;
CLOSE cursordctoitem;


return true;
END;
$function$
