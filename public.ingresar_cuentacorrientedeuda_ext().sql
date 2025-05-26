CREATE OR REPLACE FUNCTION public.ingresar_cuentacorrientedeuda_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       rccconceptotipo record;
BEGIN
/*


 perform contabilidad_generarminutaimputacion (concat('{iddeuda=' ,NEW.iddeuda,',idcentrodeuda=', NEW.idcentrodeuda, ',idpago=', NEW.idpago, ' , idcentropago=',NEW.idcentropago,'}'));
*/
      -- 1 buscar el id de la configuración de la cuenta que corresponde
      -- 2 Si el registro no se corresponde con una deuda de PP / T / PA entonces busco la configuracion de la cuenta contable para la registración contable
      -- Luego inserto en la tabla cuentacorrientedeuda_ext
 
       SELECT INTO rccconceptotipo * 
       FROM cuentacorrienteconceptotipo
       WHERE idconcepto =NEW.idconcepto 
             AND NOT NULLVALUE(	ccctgeneraregistroccd_ext ) -- genera registro en la tabla cuentacorrientedeuda_ext 
             AND  NOT NULLVALUE(ccctconfigdefecto) -- tiene una configuracion por defecto
             AND NULLVALUE(ccctfechahasta);  -- y es una configuracion que se encuentra vigente

      IF FOUND THEN
                -- Busco la cuenta contable definida por defecto 
                
             INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
             VALUES(NEW.iddeuda  , NEW.idcentrodeuda,rccconceptotipo.idcuentacorrienteconceptotipo  ,NOW());

      END IF;       


      RETURN NEW;
     
END;
$function$
