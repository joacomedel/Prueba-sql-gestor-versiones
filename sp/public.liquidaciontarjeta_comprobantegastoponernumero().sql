CREATE OR REPLACE FUNCTION public.liquidaciontarjeta_comprobantegastoponernumero()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* Se ingresan los datos de la recepcionÂº*/

DECLARE
       curcomprobante refcursor;
       regcomprobante record;

	   cgcant integer;
	   laliqtarjetant integer;


BEGIN
    

       OPEN curcomprobante FOR  SELECT *  FROM liquidaciontarjetacomprobantegasto
                                order by idliquidaciontarjeta , idcentroliquidaciontarjeta ;
       cgcant = -1;
       laliqtarjetant = -1;
       -- recorro los comprobantes
       FETCH curcomprobante INTO regcomprobante;
       WHILE  found LOOP
                      IF (laliqtarjetant <> regcomprobante.idliquidaciontarjeta) THEN
                              cgcant = 1;
                      END IF;
                    
                      UPDATE liquidaciontarjetacomprobantegasto
                      SET    ltcgnumero =  cgcant
                      WHERE  idliquidaciontarjeta = regcomprobante.idliquidaciontarjeta and
                             idcentroliquidaciontarjeta = regcomprobante.idcentroliquidaciontarjeta and
                             nroregistro = regcomprobante.nroregistro and
                             anio = regcomprobante.anio ;
                      cgcant = cgcant +1;
                      laliqtarjetant = regcomprobante.idliquidaciontarjeta;
         FETCH curcomprobante INTO regcomprobante;
         
        END LOOP;
        CLOSE curcomprobante;

RETURN cgcant;
END;
$function$
