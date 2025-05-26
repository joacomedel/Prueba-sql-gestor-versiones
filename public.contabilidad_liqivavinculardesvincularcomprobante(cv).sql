CREATE OR REPLACE FUNCTION public.contabilidad_liqivavinculardesvincularcomprobante(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	resp character varying;
        rperiodofiscal RECORD;
        rparam  RECORD;
        rfechas RECORD;
        ccomprobantes CURSOR FOR SELECT * FROM temp_comprobantes;
        uncomp RECORD;
BEGIN
  
  EXECUTE sys_dar_filtros($1) INTO rparam;
  OPEN ccomprobantes;
  FETCH ccomprobantes INTO uncomp;
  WHILE found LOOP
 
      IF (rparam.accion = 'vincular')  THEN

         IF (rparam.pftipoiva = 'C')  THEN
                     INSERT INTO contabilidad_periodofiscalreclibrofact(idperiodofiscal , idcentroregional, idrecepcion) 
                            VALUES(rparam.idperiodofiscal,uncomp.idcentroregional,uncomp.idrecepcion);
         END IF; 
         IF (rparam.pftipoiva = 'V')  THEN
                    INSERT INTO contabilidad_periodofiscalfacturaventa(idperiodofiscal , nrofactura, tipocomprobante,nrosucursal,tipofactura) 
                           VALUES(rparam.idperiodofiscal , uncomp.nrofactura, uncomp.tipocomprobante,uncomp.nrosucursal,uncomp.tipofactura) ;
         END IF; 
  END IF;
  IF (rparam.accion = 'desvincular')  THEN
         IF (rparam.pftipoiva = 'C')  THEN
                    DELETE FROM contabilidad_periodofiscalreclibrofact 
                    WHERE idperiodofiscal =rparam.idperiodofiscal  AND idrecepcion =uncomp.idrecepcion  
                           AND  idcentroregional = uncomp.idcentroregional ;
         END IF; 
         IF (rparam.pftipoiva = 'V')  THEN
                   DELETE FROM contabilidad_periodofiscalfacturaventa 
                   WHERE idperiodofiscal =rparam.idperiodofiscal AND  nrofactura =uncomp.nrofactura 
                         AND tipocomprobante =uncomp.tipocomprobante AND  nrosucursal =uncomp.nrosucursal 
                         AND  tipofactura =uncomp.tipofactura;
        END IF;

  END IF;
  FETCH ccomprobantes INTO uncomp;
  END LOOP;

return resp;
END;
$function$
