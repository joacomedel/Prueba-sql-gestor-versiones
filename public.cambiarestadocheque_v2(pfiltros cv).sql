CREATE OR REPLACE FUNCTION public.cambiarestadocheque_v2(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   rusuario record;
   --datocheque record;
   rfiltros record;

BEGIN
--BelenA SP "nuevo" para hacer generico el cambiarestado y enviarle cualquier dato por parametro de ser necesario

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;
         --Modifico el ultimo estado y le pongo cefechafin = now()
         UPDATE chequeestado
         SET  cefechafin = NOW()
              ,cecomentario = concat(cecomentario,' | Modificado desde sp cambiarestadocheque_v2')
              , idusuario =  rusuario.idusuario
         WHERE idcheque=rfiltros.idcheque
               AND idcentrocheque=rfiltros.idcentrocheque and nullvalue(cefechafin);
                
          -- Ingreso el nuevo estado
         INSERT INTO  chequeestado(cefechaini,idchequeestadotipo,idcheque,idcentrocheque,idusuario,cecomentario)
         VALUES(now(), rfiltros.idchequeestadotipo,rfiltros.idcheque,rfiltros.idcentrocheque,
            rusuario.idusuario,rfiltros.cecomentario);


         -- Si el tipo de cambio de estado del cheque es "Cobrado" que le cambie el estado del "cfechacobro" en cheque.
         -- 5 es Cobrado
         IF (rfiltros.idchequeestadotipo = 5) THEN
         	UPDATE cheque
         	SET 	cfechacobro=rfiltros.fechacobro
         	WHERE idcheque=rfiltros.idcheque AND idcentrocheque=rfiltros.idcentrocheque;
         END IF;

return true;
END;
$function$
