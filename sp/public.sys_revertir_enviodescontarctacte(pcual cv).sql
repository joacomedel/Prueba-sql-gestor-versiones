CREATE OR REPLACE FUNCTION public.sys_revertir_enviodescontarctacte(pcual character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$declare
     vresultado bigint;
BEGIN

vresultado = 0;
UPDATE cuentacorrientedeuda SET fechaenvio = null WHERE (iddeuda,idcentrodeuda) IN (
	SELECT idmovimiento as iddeuda,idcentromovimiento as idcentrodeuda 
	FROM enviodescontarctactev2 
	WHERE idenviodescontarctacte = pcual::bigint
);

DELETE FROM enviodescontarctactev2 WHERE idenviodescontarctacte = pcual::bigint; 

return vresultado;
END;
$function$
