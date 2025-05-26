CREATE OR REPLACE FUNCTION public.verificarcompensacionasientoctacte()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--VARIABLES
  respuesta BOOLEAN;

--RECORD
   rexistedato RECORD;
 
BEGIN


 CREATE TEMP TABLE reciboautomaticoctacte as (
SELECT 
ccp.idpago,ccp.idcentropago, ccd.iddeuda, ccd.idcentrodeuda,
CASE WHEN ccd.idconcepto = 360 OR ccd.idconcepto = 372 THEN 91
WHEN  ccd.idconcepto = 374 OR ccd.idconcepto = 373 THEN 97
WHEN  ccd.idconcepto = 387  THEN 3
END as idvalorescaja
,round(ccdp.importeimp::numeric,2) as importeimp
,ccdp.fechamovimientoimputacion
,ccp.nrodoc, ccp.tipodoc , ccp.movconcepto  
,ccd.idconcepto as conceptodeuda,ccp.idconcepto as conceptopago,migracion.fechamigracion AS fechaemision 
,null as idrecibo, null as idcentrorecibo
FROM cuentacorrientedeuda ccd  
JOIN cuentacorrientedeudapago ccdp USING(iddeuda,idcentrodeuda)
JOIN cuentacorrientepagos ccp USING(idpago,idcentropago)
JOIN tempimputacion USING(idpago,idcentropago)
LEFT JOIN (SELECT idpago,idcentropago,fechaini as fechamigracion  
	  FROM informefacturacionestado
	  NATURAL JOIN informefacturacioncobranza
	  WHERE idinformefacturacionestadotipo = 8 AND nullvalue(fechafin) 
) as migracion USING(idpago,idcentropago)
WHERE  ccd.idconcepto <>ccp.idconcepto AND ccp.idconcepto<>999
AND not (ccd.idconcepto=360 AND ccp.idconcepto =372) 
--and ccp.nrodoc = '13850345'
AND ccp.idcomprobantetipos = 0 
AND ccdp.fechamovimientoimputacion >= migracion.fechamigracion
AND round(ccdp.importeimp::numeric,2) > 0.01
--GROUP BY ccp.idpago, ccp.nrodoc, ccp.tipodoc  , ccp.movconcepto 
--ORDER BY ccp.idpago 

UNION 

SELECT ccp.idpago,ccp.idcentropago, ccd.iddeuda, ccd.idcentrodeuda,
CASE WHEN ccd.idconcepto = 360 OR ccd.idconcepto = 372 THEN 91
WHEN  ccd.idconcepto = 374 OR ccd.idconcepto = 373 THEN 97
WHEN  ccd.idconcepto = 387  THEN 3
END as idvalorescaja
,round(ccdp.importeimp::numeric,2) as importeimp
,ccdp.fechamovimientoimputacion
,ccp.nrodoc, ccp.tipodoc , ccp.movconcepto  
,ccd.idconcepto as conceptodeuda,ccp.idconcepto as conceptopago,null as fechaemision
,null as idrecibo, null as idcentrorecibo
FROM cuentacorrientedeuda ccd  
JOIN cuentacorrientedeudapago ccdp USING(iddeuda,idcentrodeuda)
JOIN cuentacorrientepagos ccp USING(idpago,idcentropago)
JOIN tempimputacion USING(idpago,idcentropago)
WHERE  ccd.idconcepto <>ccp.idconcepto and ccp.idconcepto<>999
AND not (ccd.idconcepto=360 AND ccp.idconcepto =372) 
--AND ccd.idconcepto<>360 AND ccp.idconcepto <>372
--and ccp.nrodoc = '12720116'
AND ccp.idcomprobantetipos <> 0 
--GROUP BY ccp.idcomprobantetipos,ccp.idpago, ccp.nrodoc, ccp.tipodoc  , ccp.movconcepto 
--ORDER BY ccp.idpago 
);

SELECT INTO rexistedato * FROM reciboautomaticoctacte;
IF FOUND THEN 
  SELECT INTO respuesta * FROM asentarcompensacionctacte();	
END IF; 

RETURN true;

END;
$function$
