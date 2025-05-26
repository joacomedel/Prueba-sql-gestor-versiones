CREATE OR REPLACE FUNCTION public.contabilidad_periodofiscal_vincularcomprobante(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rparam RECORD;
    rperiodofiscal  record;
    respuesta character varying;
    sparam  character varying;
rexiste record;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;
     ---  1 -  Busco el periodo fiscal al que corresponde el comprobante
         sparam = contabilidad_periodofiscal_info (concat('{fechaemicioncomp=', rparam.fechaemicioncomp,',pftipoiva=',rparam.pftipoiva,'}'));  
     IF not nullvalue(sparam) THEN	
            EXECUTE sys_dar_filtros(sparam) INTO rperiodofiscal;
     
   
	    respuesta = concat('idperiodofiscal=',rperiodofiscal.idperiodofiscal);
	    IF (rparam.pftipoiva ='C') THEN
		INSERT INTO contabilidad_periodofiscalreclibrofact(idperiodofiscal, idrecepcion, idcentroregional)
		       VALUES (rperiodofiscal.idperiodofiscal, rparam.idrecepcion, rparam.idcentroregional);
	     
	     END IF;
	     IF (rparam.pftipoiva ='V') THEN
                SELECT INTO rexiste *
                FROM contabilidad_periodofiscalfacturaventa
                WHERE  nrofactura= rparam.nrofactura and tipocomprobante =  rparam.tipocomprobante 
                   and nrosucursal = rparam.nrosucursal and tipofactura=  rparam.tipofactura;
                IF NOT FOUND THEN 
		       INSERT INTO contabilidad_periodofiscalfacturaventa(idperiodofiscal, nrofactura, tipocomprobante, nrosucursal, tipofactura)
		       VALUES(rperiodofiscal.idperiodofiscal, rparam.nrofactura, rparam.tipocomprobante, rparam.nrosucursal, rparam.tipofactura);
                END IF;

	     END IF;	
     END IF;	
    
return respuesta;
END;
$function$
