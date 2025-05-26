CREATE OR REPLACE FUNCTION public.contabilidad_composicion_cuentacorriente_contemp(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
  afil_ctacte RECORD; 
BEGIN

     respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;  

    CREATE TEMP TABLE contabilidad_composicion_cuentacorriente_temp AS (
	SELECT  UPPER(concat(afil.nrodoc,' - ',apellido, ' ', nombres)) as identificación
			, CASE WHEN (c.idcomprobantetipos = 21) THEN  concat (id.tipofactura,' ',id.nrosucursal,'-', id.nrofactura) 
       			   WHEN (c.idcomprobantetipos = 4 OR c.idcomprobantetipos = 2 ) THEN concat('ORDEN ',d.idcomprobante/100,'-',d.idcomprobante%100) 
				   WHEN (c.idcomprobantetipos = 31) THEN concat('ORDEN - REC  ',d.idcomprobante/100,'-',d.idcomprobante%100) 
				   WHEN (c.idcomprobantetipos = 18) THEN  concat('PREST. ASIS: ',split_part( split_part(d.movconcepto, 'Prestamo', 2) ,'.', 1),'-', d.idcentrodeuda)  
				   WHEN (c.idcomprobantetipos = 7 ) THEN  concat('PREST. TUR: ',split_part( split_part(d.movconcepto, 'Prestamo', 2) ,'.', 1),'-', d.idcentrodeuda)   
				   WHEN (c.idcomprobantetipos = 17) THEN  concat('PREST. PP ',split_part( split_part(d.movconcepto, 'Prestamo', 2) ,'.', 1),'-', d.idcentrodeuda) 
				   WHEN (c.idcomprobantetipos = 12) THEN  d.movconcepto
				   WHEN (c.idcomprobantetipos = 20) THEN  concat('ORDEN - PRES  ',d.idcomprobante/100,'-',d.idcomprobante%100) 
				   WHEN (c.idcomprobantetipos = 56) THEN  concat('ORDEN - ONLINE  ',d.idcomprobante/100,'-',d.idcomprobante%100) 
				   WHEN (c.idcomprobantetipos = 48) THEN  concat('ORDEN - ODONTO  ',d.idcomprobante/100,'-',d.idcomprobante%100)   
       		ELSE 
           			concat( c.idcomprobantetipos ,':',  c.ctdescripcion ,' -',d.idcomprobante)
 			END as comp_deuda
       		, d.idcomprobante as idcomprobante, d.fechamovimiento as fecha_deuda, d.importe as imp_deuda,abs(d.saldo) as saldo_actual_deuda
       		, dp.fechamovimientoimputacion as fecha_imputacion, dp.importeimp as importeimp 
        	,CASE WHEN (p.idcomprobantetipos =  0 ) THEN  concat('REC:  ',p.idcomprobante,'-',p.idcentropago)   
         		  WHEN (p.idcomprobantetipos = 21) THEN  concat (ip.tipofactura,' ',ip.nrosucursal,'-',ip.nrofactura) 
             	  ELSE 
                		p.movconcepto
            END as  pago_comp
			, p.fechamovimiento as fecha_pago, p.idcomprobante as comp_pago,abs( p.importe) as imp_pago ,abs( p.saldo) as saldo_actual_pago
 	FROM cuentacorrientedeuda as d
	JOIN comprobantestipos as c USING(idcomprobantetipos)
	LEFT JOIN informefacturacion as id ON(id.nroinforme*100 + id.idcentroinformefacturacion =  d.idcomprobante)
	LEFT JOIN persona as afil USING (nrodoc)
	LEFT JOIN cuentacorrientedeudapago as dp USING (iddeuda,idcentrodeuda)
	LEFT JOIN cuentacorrientepagos as p USING (idpago,idcentropago)
	LEFT JOIN informefacturacion as ip ON(ip.nroinforme*100 + ip.idcentroinformefacturacion =  p.idcomprobante)
	WHERE   d.fechamovimiento <='2023-02-14' 
      		AND d.saldo <> 0
      		AND afil.tipodoc <100

	UNION

	SELECT  UPPER(concat(afil.nrodoc,' - ',apellido, ' ', nombres)) as identificación 
			,' ' as  deuda_comp
	        , d.idcomprobante as idcomprobante , d.fechamovimiento as fecha_deuda, d.importe as imp_deuda, abs(d.saldo) as saldo_actual_deuda
   			, dp.fechamovimientoimputacion as fecha_imputacion, importeimp 
   			,CASE WHEN (p.idcomprobantetipos =  0 ) THEN  concat('REC:  ',p.idcomprobante,'-',p.idcentropago)   
         		  WHEN (c.idcomprobantetipos = 21) THEN  concat (ip.tipofactura,' ',ip.nrosucursal,'-', ip.nrofactura) 
         		  ELSE 
            			p.movconcepto
    		END as  pago_comp
   			,p.fechamovimiento as fecha_pago, p.idcomprobante as comp_pago ,abs(p.importe) as  imp_pago,abs( p.saldo) as saldo_actual_pago
           
	FROM cuentacorrientepagos as p
	JOIN comprobantestipos as c USING(idcomprobantetipos)
	LEFT JOIN informefacturacion ip ON(ip.nroinforme*100 + ip.idcentroinformefacturacion =  p.idcomprobante)
	LEFT JOIN persona as afil USING (nrodoc)
	LEFT JOIN cuentacorrientedeudapago as dp USING (idpago,idcentropago)
	LEFT JOIN cuentacorrientedeuda as d  USING (iddeuda,idcentrodeuda) 
	WHERE p.fechamovimiento <='2023-02-14' 
      		AND abs(p.saldo) > 0
      		AND afil.tipodoc <100
      		AND nullvalue(dp.idpago) 
);
     
   
	IF (rparam.listado = 'resumen') THEN
	     CREATE TEMP TABLE contabilidad_composicion_cuentacorriente_resumen_temp AS (
		  SELECT *
				FROM 
				(     SELECT identificación  , SUM(imp_deuda)as imp_deuda, SUM(saldo_actual_deuda)as saldo_actual_deuda ,SUM(importeimp) as importeimp_deuda
					  FROM (

							SELECT  identificación , comp_deuda, fecha_deuda,imp_deuda,saldo_actual_deuda ,SUM(importeimp) as importeimp
							FROM contabilidad_composicion_cuentacorriente_temp
							GROUP BY identificación , comp_deuda, fecha_deuda,imp_deuda,saldo_actual_deuda
					  ) as td
					  GROUP BY identificación  
				) as afil_deuda
				JOIN ( SELECT identificación  , SUM(imp_pago)as imp_pago, SUM(saldo_actual_pago)as saldo_actual_pago ,SUM(importeimp) as importeimp_pago
					  FROM (

							SELECT identificación , pago_comp, fecha_pago,imp_pago,saldo_actual_pago,SUM(importeimp) as importeimp

							FROM contabilidad_composicion_cuentacorriente_temp
							GROUP BY identificación , pago_comp, fecha_pago,imp_pago,saldo_actual_pago

					  ) as tp
					  GROUP BY identificación
				) as afil_pago USING(identificación)

				ORDER BY identificación

		);

            
           	
	
	
	END IF;

     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
