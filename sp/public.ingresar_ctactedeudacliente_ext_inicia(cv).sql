CREATE OR REPLACE FUNCTION public.ingresar_ctactedeudacliente_ext_inicia(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       rccconceptotipo record;
BEGIN
 
      -- 1 buscar el id de la configuración de la cuenta que corresponde
      -- 2 Si el registro no se corresponde con una deuda de PP / T / PA entonces busco la configuracion de la cuenta contable para la registración contable
      -- Luego inserto en la tabla ctactedeudacliente_ext
 
       SELECT INTO rccconceptotipo * 
       FROM mapeocuentascontablesconcepto  JOIN cuentacorrienteconceptotipo ON nroconcepto = idconcepto
       WHERE nrocuentac =NEW.nrocuentac 
             AND NOT NULLVALUE(	ccctgeneraregistroccd_ext ) -- genera registro en la tabla cuentacorrientedeuda_ext 
             AND  NOT NULLVALUE(ccctconfigdefecto) -- tiene una configuracion por defecto
             AND NULLVALUE(ccctfechahasta)   -- y es una configuracion que se encuentra vigente

       ORDER BY nroconcepto  asc
       LIMIT 1; 
 
       IF FOUND THEN
             -- Busco la cuenta contable definida por defecto                 
             INSERT INTO ctactedeudacliente_ext (iddeuda,idcentrodeuda,  idcuentacorrienteconceptotipo)
             VALUES(NEW.iddeuda, NEW.idcentrodeuda,rccconceptotipo.idcuentacorrienteconceptotipo);

       END IF;       


       RETURN NEW;
     
END;
$function$
