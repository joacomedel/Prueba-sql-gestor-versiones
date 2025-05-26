CREATE OR REPLACE FUNCTION public.ingresar_ctactedeudacliente_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       rccconceptotipo record;
BEGIN
 
      -- 1 buscar el id de la configuración de la cuenta que corresponde
      -- 2 Si el registro no se corresponde con una deuda de PP / T / PA entonces busco la configuracion de la cuenta contable para la registración contable
      -- Luego inserto en la tabla ctactedeudacliente_ext
 
       SELECT INTO rccconceptotipo * 
       FROM  cuentacorrienteconceptotipo
       WHERE nrocuentacontable =NEW.nrocuentac 
              AND NOT NULLVALUE(ccctgeneraregistroccd_ext ) -- genera registro en la tabla cuentacorrientedeuda_ext 
              AND  NOT NULLVALUE(ccctconfigdefecto) -- tiene una configuracion por defecto
              AND NULLVALUE(ccctfechahasta)   -- y es una configuracion que se encuentra vigente
                  ;                 
 
       IF FOUND THEN
             -- Busco la cuenta contable definida por defecto                 
             INSERT INTO ctactedeudacliente_ext (iddeuda,idcentrodeuda,  idcuentacorrienteconceptotipo, idconcepto)
             VALUES(NEW.iddeuda, NEW.idcentrodeuda,rccconceptotipo.idcuentacorrienteconceptotipo,rccconceptotipo.idconcepto);
       ELSE 
--KR 01-09-22 hay casos donde no existe la configuracion en la tabla cuentacorrienteconceptotipo ej nrocuentac=10812, aplica al universo de los clientes TKT 5342
      --KR 21-09-22 Para turismo aunque no se encuentre no se debe insertar pq ya se inserta en el sp generarprestamocuotas
      --idcomprobantetipos = 7 VER TABLA comprobantestipos
          IF (NEW.idcomprobantetipos <>7) THEN  
             INSERT INTO ctactedeudacliente_ext (iddeuda,idcentrodeuda)
             VALUES(NEW.iddeuda, NEW.idcentrodeuda);
          
          END IF;
       END IF;       


       RETURN NEW;
     
END;$function$
