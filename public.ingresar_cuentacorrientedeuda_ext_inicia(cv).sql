CREATE OR REPLACE FUNCTION public.ingresar_cuentacorrientedeuda_ext_inicia(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       c_pagorechazado refcursor;
       rpago record;
       asientodescripcion varchar;
       rcuentadebe record;
	
	   rfiltros  record;
	   rimputacion  record;
       rresp  varchar;

	   elconcepto varchar;
	   elbeneficiario varchar;

       rccdeuda  record;
       eliddeuda bigint;
       elidcentrodeuda integer;
rccconceptotipo record;
 
BEGIN  
     
	 --asientogenerico_crear_9  NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago
	 EXECUTE sys_dar_filtros($1) INTO rfiltros;
     eliddeuda = rfiltros.iddeuda;
     elidcentrodeuda = rfiltros.idcentrodeuda;
     rresp = null;

     SELECT INTO rccdeuda *
     FROM cuentacorrientedeuda
     WHERE iddeuda = eliddeuda and idcentrodeuda = elidcentrodeuda ;

     SELECT INTO rccconceptotipo * 
     FROM cuentacorrienteconceptotipo
     WHERE idconcepto =rccdeuda.idconcepto 
             AND  NULLVALUE(	ccctgeneraregistroccd_ext ) -- genera registro en la tabla cuentacorrientedeuda_ext 
         --    AND  NOT NULLVALUE(ccctconfigdefecto) -- tiene una configuracion por defecto
             AND NULLVALUE(ccctfechahasta);  -- y es una configuracion que se encuentra vigente

      IF FOUND THEN
                -- Busco la cuenta contable definida por defecto 
             IF( NOT NULLVALUE(rccconceptotipo.ccctconfigdefecto) ) THEN  -- tiene una configuracion por defecto
                     INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                      VALUES(eliddeuda , elidcentrodeuda,rccconceptotipo.idcuentacorrienteconceptotipo  ,NOW());
                      rresp = $1;

              ELSE
                  --No tiene configuracion por defecto
      
                  
                   -- Si se corresponde con un prestamo PP 
                   -- IF (rccconceptotipo.idprestamotipos = 3 )THEN 
                 -- Si se corresponde con un Turismo         
                 IF (rccconceptotipo.idprestamotipos = 1 )THEN 
                       IF  (rccdeuda.movconcepto ilike '%Cuota prestamo por Plan pago cuenta corriente . Prestamo%' 
                       AND not rccdeuda.movconcepto ilike '%Interes%' 
                       AND not rccdeuda.movconcepto ilike '%iva%'  )  THEN              

                     -- engresa la deuda

                        
                        INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                        VALUES(eliddeuda , elidcentrodeuda,  rccconceptotipo.idcuentacorrienteconceptotipo  ,NOW());
rresp = $1;
                 END IF;
                 
                   IF  (rccdeuda.movconcepto ilike '%Cuota prestamo por Plan pago cuenta corriente . Prestamo%' 
                       AND rccdeuda.movconcepto ilike '%Interes%' 
                       AND not rccdeuda.movconcepto ilike '%iva%'  )  THEN     
                           -- ingresa el interes

                           INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                           VALUES(eliddeuda   , centro(),rccconceptotipo.idcuentacorrienteconceptotipo_interes,NOW());
rresp = $1;
                  END IF;

                   IF  (rccdeuda.movconcepto ilike '%Cuota prestamo por Plan pago cuenta corriente . Prestamo%' 
                       AND rccdeuda.movconcepto ilike '%Interes%' 
                       AND rccdeuda.movconcepto ilike '%iva%'  )  THEN    

                       -- ingresa el IVA interes

                             INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                             VALUES(eliddeuda   , centro(),rccconceptotipo.idcuentacorrienteconceptotipo_ivainteres	,NOW());
rresp = $1;
                   END IF;

              END IF;
 
           
            END IF;
       
  END IF;
      RETURN rresp;
     
END;
$function$
