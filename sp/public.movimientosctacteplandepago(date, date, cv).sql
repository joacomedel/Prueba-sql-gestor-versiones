CREATE OR REPLACE FUNCTION public.movimientosctacteplandepago(date, date, character varying)
 RETURNS SETOF movimientoctacteplanpagos
 LANGUAGE sql
AS $function$
SELECT
min(fechaprestamo)::varchar as fechamovimiento
,null as idconcepto
,sum(CASE WHEN nullvalue(importedeuda) THEN importecuota ELSE importedeuda END) as importedeuda
,sum(CASE WHEN nullvalue(importeimp) THEN
 CASE WHEN nullvalue(ctacte.idcomprobante) THEN importecuota ELSE 0 END
 ELSE importeimp END) as importepagado
,null::varchar as fechapagoprobable
,null::varchar as fechapago
,null as iddeuda
,null as idcentrodeuda
,null as movconcepto
,null as formapago
,null as estadocuota
,null as nomape
,null as nrodoc
,null as barra
,null as estadoconsumo
,'Sin Facturas' as infofacturas
,null as movconceptopago
,null as infopago
FROM prestamo
LEFT JOIN prestamoestado pe USING(idprestamo,idcentroprestamo)
LEFT JOIN (SELECT idprestamo, idcentroprestamo, text_concatenar(concat(fechaemision , ' ' ,tipofactura,' ' , nrosucursal,'-',nrofactura,' imp.efc $',importeefectivo,' imp.ctacte $',importectacte)) as facturas
			FROM informefacturacionturismo
			NATURAL JOIN informefacturacion
			NATURAL JOIN facturaventa
			NATURAL JOIN informefacturacionestado ife
			NATURAL JOIN consumoturismo
			NATURAL JOIN prestamo	
			WHERE ife.idinformefacturacionestadotipo = 4 AND nullvalue(ife.fechafin)
			group by idprestamo, idcentroprestamo
) as facturasqueseusaron USING(idprestamo,idcentroprestamo)
NATURAL JOIN persona
NATURAL JOIN prestamocuotas as pc
LEFT JOIN (
     SELECT d.idcomprobante,d.idcomprobantetipos, CASE WHEN nullvalue(p.iddeuda) THEN 'sedebe' ELSE 'sepago' END as estadocuota
     ,d.movconcepto, p.importeimp,d.idconcepto,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,p.fechamovimiento as fechapago
     ,p.movconceptopago,p.infopago
     FROM cuentacorrientedeuda as d
     LEFT JOIN (
            SELECT iddeuda,idcentrodeuda,sum(importeimp) as importeimp,max(fechamovimiento) as fechamovimiento
			,text_concatenar(infopago) as infopago,text_concatenar(concat(movconcepto , ' ')) as movconceptopago
			FROM cuentacorrientepagos
			LEFT JOIN cuentacorrientedeudapago  USING (idpago,idcentropago)
			LEFT JOIN ( SELECT idpago,idcentropago
						,text_concatenar(concat('F.Informe ' ,inf.fechainforme , ' Nro.Informe ' , i.nroinforme , '-' , i.idcentroinformefacturacion , ' F.D ' ,  i.fechadesde , ' F.H ' , i.fechahasta)) as infopago
            			FROM informefacturacioncobranza i
						NATURAL JOIN  informefacturacion inf
						NATURAL JOIN informefacturacionestado ife
						WHERE  nullvalue(ife.fechafin) AND ife.idinformefacturacionestadotipo = 8
						GROUP BY idpago,idcentropago
            			) infopagos USING(idpago,idcentropago)
            WHERE  fechamovimiento <= $2
            GROUP BY iddeuda,idcentrodeuda
           )as p USING (iddeuda,idcentrodeuda)
           WHERE  d.idcomprobantetipos = 17 --Plan de Pagos
   ) as ctacte ON ctacte.idcomprobante = pc.idprestamocuotas * 10 + pc.idcentroprestamocuota
				AND ctacte.idcomprobantetipos = pc.idcomprobantetipos
    WHERE prestamo.fechaprestamo <= $2
          AND pc.idcomprobantetipos = 17 --Plan de Pagos

UNION

     SELECT fechamovimiento::varchar,idconcepto,importedeuda,importepagado,fechapagoprobable::varchar,fechapago::varchar,iddeuda,idcentrodeuda
            ,movconcepto,formapago,estadocuota,nomape,nrodoc,barra::VARCHAR,estadoconsumo,infofacturas,movconceptopago,infopago
     FROM (
SELECT fechaprestamo as fechamovimiento
,idconcepto
,CASE WHEN nullvalue(importedeuda) THEN importecuota ELSE importedeuda END as importedeuda
,CASE WHEN nullvalue(importeimp) THEN
 CASE WHEN nullvalue(ctacte.idcomprobante) THEN importecuota ELSE 0 END
 ELSE importeimp END as importepagado
,pc.fechapagoprobable
,ctacte.fechapago
,iddeuda,idcentrodeuda
,CASE WHEN nullvalue(movconcepto) THEN concat('Prestamo Asistencial ',idprestamo , '-' , idcentroprestamo) ELSE movconcepto END as movconcepto
,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'Efectivo' ELSE 'CTa.Cte' END as formapago
,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'sepago' ELSE estadocuota END as estadocuota
,concat(persona.nombres , ' ' , persona.apellido) as nomape
,persona.nrodoc
,persona.barra
,CASE WHEN (pe.idprestamoestadotipos = 3) THEN 'Anulado' ELSE 'Vigente' END as estadoconsumo
,'Sin Facturas'::varchar as infofacturas
,movconceptopago,infopago
FROM prestamo
LEFT JOIN prestamoestado pe USING(idprestamo,idcentroprestamo)
LEFT JOIN (SELECT idprestamo, idcentroprestamo, text_concatenar(concat(fechaemision , ' ' ,tipofactura,' ' , nrosucursal,'-',nrofactura,' imp.efc $',importeefectivo,' imp.ctacte $',importectacte)) as facturas
			FROM informefacturacionturismo
			NATURAL JOIN informefacturacion
			NATURAL JOIN facturaventa
			NATURAL JOIN informefacturacionestado ife
			NATURAL JOIN consumoturismo
			NATURAL JOIN prestamo	
			WHERE ife.idinformefacturacionestadotipo = 4 AND nullvalue(ife.fechafin)
			group by idprestamo, idcentroprestamo
) as facturasqueseusaron USING(idprestamo,idcentroprestamo)
NATURAL JOIN persona
NATURAL JOIN prestamocuotas as pc
LEFT JOIN (
SELECT d.idcomprobante,d.idcomprobantetipos, CASE WHEN nullvalue(p.iddeuda) THEN 'sedebe' ELSE 'sepago' END as estadocuota
,d.movconcepto, p.importeimp,d.idconcepto,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,p.fechamovimiento as fechapago
,p.movconceptopago,p.infopago
FROM cuentacorrientedeuda as d
LEFT JOIN (
             SELECT iddeuda,idcentrodeuda,sum(importeimp) as importeimp,max(fechamovimiento) as fechamovimiento
			,text_concatenar(infopago) as infopago,text_concatenar(concat(movconcepto , ' ')) as movconceptopago
			FROM cuentacorrientepagos
			LEFT JOIN cuentacorrientedeudapago  USING (idpago,idcentropago)
			LEFT JOIN ( SELECT idpago,idcentropago
						,text_concatenar(concat('F.Informe ' ,inf.fechainforme , ' Nro.Informe ' , i.nroinforme , '-' , i.idcentroinformefacturacion , ' F.D ' ,  i.fechadesde , ' F.H ' , i.fechahasta)) as infopago
            			FROM informefacturacioncobranza i
						NATURAL JOIN  informefacturacion inf
						NATURAL JOIN informefacturacionestado ife
						WHERE  nullvalue(ife.fechafin) AND ife.idinformefacturacionestadotipo = 8
						GROUP BY idpago,idcentropago
            			) infopagos USING(idpago,idcentropago)
            WHERE  fechamovimiento <= $1
            GROUP BY iddeuda,idcentrodeuda
           )as p USING (iddeuda,idcentrodeuda)
           WHERE  d.idcomprobantetipos = 17 --Plan de Pagos
) as ctacte ON ctacte.idcomprobante = pc.idprestamocuotas * 10 + pc.idcentroprestamocuota
				AND ctacte.idcomprobantetipos = pc.idcomprobantetipos
WHERE ( fechaprestamo >= $2 AND fechaprestamo < $1 )
AND ($3 = '' OR  estadocuota = $3 )
AND pc.idcomprobantetipos = 17 --Plan de Pagos
) as t
$function$
