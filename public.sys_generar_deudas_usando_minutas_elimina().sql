CREATE OR REPLACE FUNCTION public.sys_generar_deudas_usando_minutas_elimina()
 RETURNS void
 LANGUAGE plpgsql
AS $function$/*
Genera deudas, usando minutas de pago
*/
DECLARE
	cpagos refcursor;
        rusuario RECORD;
        ralerta RECORD;
	vminuta varchar;
	vopc varchar;
	vpop varchar;
  

BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
--46 personas
OPEN cpagos FOR SELECT * FROM temp_devolver_2
                         JOIN cuentacorrientepagos USING(nrodoc,tipodoc) 
                          WHERE not nullvalue(nrooperacion) AND abs(saldo) > 1
                          AND idcomprobantetipos = 0 AND movconcepto ilike 'Descuento UNC liq 504%'
                          AND nullvalue(nrominuta) AND abs(saldo) <> abs(temp_devolver_2.importe)
			  --AND nrodoc = '35592957'
                          ORDER BY nrodoc
                          --limit 1
                          ; 
FETCH cpagos into ralerta;
WHILE  found LOOP

-- MaLaPi reguistro el nro de minuta que tengo que modidicar el importe 
UPDATE temp_devolver_2  SET nrominuta = t.nrominuta
FROM (
SELECT split_part(split_part(movconcepto,'Generada desde MP:', 2),' ',1)  as nrominuta,idcomprobante,idcomprobantetipos,nrodoc,tipodoc  
FROM cuentacorrientedeuda 
WHERE nrodoc = ralerta.nrodoc AND movconcepto ilike 'Generada desde MP:%' ) as t
WHERE temp_devolver_2.nrodoc = t.nrodoc;

-- MaLapi modifico el importe y el saldo de la deuda luego de modificar el origen de la deuda
UPDATE cuentacorrientedeuda SET saldo = t.importereal,importe = t.importereal, movconcepto = concat(movconcepto,'. Le modifico el importe de ',importe,' a ',t.importereal)
FROM (
SELECT iddeuda,idcentrodeuda
,abs(temp_devolver_2.importe) as importereal,split_part(split_part(movconcepto,'Generada desde MP:', 2),' ',1)  as nrominuta,idcomprobante,idcomprobantetipos,nrodoc,tipodoc  
FROM cuentacorrientedeuda
JOIN  temp_devolver_2 USING(nrodoc,tipodoc)
WHERE cuentacorrientedeuda.nrodoc = ralerta.nrodoc AND movconcepto ilike 'Generada desde MP:%'
) as t
WHERE t.nrodoc = cuentacorrientedeuda.nrodoc AND t.iddeuda = cuentacorrientedeuda.iddeuda AND t.idcentrodeuda = cuentacorrientedeuda.idcentrodeuda;
 
-- Modifico el Consumoasi, que es el comprobante que genero la deuda real
UPDATE consumoasiv2 SET caimporte = t.importereal, caconcepto = t.nuevoconcepto 
FROM (
SELECT iddeuda,idcentrodeuda
,abs(temp_devolver_2.importe) as importereal,movconcepto as nuevoconcepto,idcomprobante,idcomprobantetipos,nrodoc,tipodoc  
FROM cuentacorrientedeuda
JOIN  temp_devolver_2 USING(nrodoc,tipodoc)
WHERE cuentacorrientedeuda.nrodoc = ralerta.nrodoc AND movconcepto ilike 'Generada desde MP:%'
) as t
WHERE t.nrodoc = consumoasiv2.nrodoc AND t.idcomprobante = consumoasiv2.idconsumoasi AND t.idcomprobantetipos = consumoasiv2.idcomprobantetipos;

-- Modifico el importe de la minuta de pago 
UPDATE ordenpago SET importetotal = abs(temp_devolver_2.importe), concepto = concat(concepto,'.Modifico importe de ',importetotal,' a ',abs(temp_devolver_2.importe)) 
FROM temp_devolver_2
WHERE nrominuta = concat(nroordenpago,'-',idcentroordenpago) 
	AND temp_devolver_2.nrodoc = ralerta.nrodoc;

UPDATE ordenpagoimputacion SET debe = abs(temp_devolver_2.importe) 
FROM temp_devolver_2
WHERE nrominuta = concat(nroordenpago,'-',idcentroordenpago) 
	AND temp_devolver_2.nrodoc = ralerta.nrodoc;

--vinculo el temp_devolver_2 con la ordenpago que genero 
UPDATE temp_devolver_2 SET nroopc = concat(idordenpagocontable,'|',idcentroordenpagocontable)
FROM ordenpagocontableordenpago
WHERE nrominuta = concat(nroordenpago,'-',idcentroordenpago);

--vinculo el temp_devolver_2 con el pago de la ordenpago que genero 
UPDATE temp_devolver_2 SET nropopc = concat(idpagoordenpagocontable,'-',idcentropagoordenpagocontable)
FROM pagoordenpagocontable
WHERE nroopc = concat(idordenpagocontable,'|',idcentroordenpagocontable);

--Modifico la orden de pago contable 
UPDATE ordenpagocontable SET opcmontototal = abs(temp_devolver_2.importe) , opcmontocontadootra = abs(temp_devolver_2.importe),opcobservacion = concat(opcobservacion,'.Modifico importe de ',opcmontototal,' a ',abs(temp_devolver_2.importe))
FROM temp_devolver_2 
WHERE nroopc = concat(idordenpagocontable,'|',idcentroordenpagocontable);

-- Modifico los datos del pago de la orden de pago contable
UPDATE pagoordenpagocontable SET popmonto = abs(temp_devolver_2.importe) , popobservacion = concat(popobservacion,'.Modifico importe de ',popmonto,' a ',abs(temp_devolver_2.importe))
FROM temp_devolver_2 
WHERE nropopc = concat(idpagoordenpagocontable,'-',idcentropagoordenpagocontable);


FETCH cpagos into ralerta;
END LOOP;
close cpagos;


END;
$function$
