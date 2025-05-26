CREATE OR REPLACE FUNCTION public.movimientosctacteturismo(date, date, character varying)
 RETURNS SETOF t_movimientoctacte
 LANGUAGE sql
AS $function$-- modifico vas 01-06-2022 para que tome como fecha de movimiento la fecha del movimiento generado en cuentacorrientedeuda

SELECT to_char( Min(fechamovimiento),'DD-MM-YYYY') as fechainimov,null as idconcepto,sum(importedeuda)as sumdeuda,
         sum(importepagado) as sumpagos,
         null as fechapagoprobable,null as fechapago
         ,null as iddeuda,null as idcentrodeuda
         ,null as movconcepto,null as formapago,null as estadocuota,null as nomape,null as nrodoc
         ,null as barra,null as estadoconsumo,null as infofacturas,null as movconceptopago,null as infopago,

         to_char(Min(fechamovimiento) ,'DD-MM-YYYY') as fechacontable

FROM (
         SELECT fechadeudactacte as fechamovimiento
                  ,CASE WHEN not nullvalue(pcborrado) THEN 0
                  WHEN nullvalue(pcborrado) AND nullvalue(importedeuda) THEN importecuota
                  WHEN nullvalue(pcborrado) AND not nullvalue(importedeuda) THEN importedeuda  END as importedeuda
                  --CASE WHEN nullvalue(importedeuda) THEN importecuota ELSE importedeuda END as importedeuda
                 ,CASE WHEN nullvalue(importeimp) THEN
	          CASE WHEN nullvalue(ctacte.idcomprobante) THEN importecuota ELSE 0 END ELSE importeimp END as importepagado
                 ,pc.fechapagoprobable
                 ,ctacte.fechapago
                 ,iddeuda,idcentrodeuda
                 ,CASE WHEN nullvalue(movconcepto) THEN concat('Prestamo Turismo ',idprestamo , '-' , idcentroprestamo) ELSE movconcepto END as movconcepto
                 ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'Efectivo' ELSE 'CTa.Cte' END as formapago
                 ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'sepago' ELSE estadocuota END as estadocuota
                 ,concat(persona.nombres , ' ' , persona.apellido) as nomape
                 ,persona.nrodoc
                 ,persona.barra
                 ,CASE WHEN cte.idconsumoturismoestadotipos = 3 THEN 'Anulado' ELSE 'Vigente' END as estadoconsumo
                 ,CASE WHEN nullvalue(facturas) THEN 'Sin Facturas' ELSE facturas END as infofacturas
                 ,movconceptopago,infopago
         FROM consumoturismo
         NATURAL JOIN consumoturismoestado cte
         NATURAL JOIN prestamo
         LEFT JOIN (
                 SELECT idprestamo, idcentroprestamo, text_concatenar(concat(fechaemision , ' ' ,tipofactura,' ' , nrosucursal,'-',nrofactura,' imp.efc $',importeefectivo,' imp.ctacte $',importectacte)) as facturas
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
                  SELECT d.fechamovimiento as fechadeudactacte, d.idcomprobante,d.idcomprobantetipos, CASE WHEN nullvalue(p.iddeuda) THEN 'sedebe' ELSE 'sepago' END as estadocuota ,d.movconcepto, p.importeimp,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,p.fechamovimiento as fechapago ,p.movconceptopago,p.infopago
                  FROM cuentacorrientedeuda as d
                  LEFT JOIN (SELECT iddeuda,idcentrodeuda,sum(importeimp) as importeimp,max(fechamovimiento) as fechamovimiento
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
                  WHERE fechamovimiento < $2
                  GROUP BY iddeuda,idcentrodeuda
       )as p USING (iddeuda,idcentrodeuda)
WHERE d.idcomprobantetipos = 7
) as ctacte ON ctacte.idcomprobante = pc.idprestamocuotas * 10 + pc.idcentroprestamocuota
				AND ctacte.idcomprobantetipos = pc.idcomprobantetipos
WHERE nullvalue(cte.ctefechafin) --AND nullvalue(pcborrado) 

) as t

WHERE fechamovimiento <= $2


UNION

SELECT to_char(fechamovimiento,'DD-MM-YYYY'),idconcepto,importedeuda,importepagado,
         to_char(fechapagoprobable,'DD-MM-YYYY'),to_char(fechapago,'DD-MM-YYYY'),iddeuda,idcentrodeuda
         ,movconcepto,formapago,estadocuota,nomape,nrodoc,barra::VARCHAR,estadoconsumo,infofacturas,movconceptopago,infopago
         ,CASE WHEN ( nullvalue(fechapago) ) THEN to_char(fechamovimiento,'DD-MM-YYYY')
         ELSE  to_char(fechapago,'DD-MM-YYYY')
         END as fechacontable




FROM (
         SELECT fechadeudactacte as fechamovimiento
         ,CASE WHEN not nullvalue(pcborrado) THEN 0
               WHEN nullvalue(pcborrado) AND nullvalue(importedeuda) THEN importecuota
               WHEN nullvalue(pcborrado) AND not nullvalue(importedeuda) THEN importedeuda
         END as importedeuda
         ,CASE WHEN nullvalue(importeimp) THEN
	 CASE WHEN nullvalue(ctacte.idcomprobante) THEN importecuota ELSE 0 END
              ELSE importeimp END as importepagado
         ,pc.fechapagoprobable
         ,ctacte.fechapago
         ,iddeuda,idcentrodeuda,idconcepto
         ,CASE WHEN nullvalue(movconcepto) THEN concat('Prestamo Turismo ',idprestamo , '-' , idcentroprestamo) ELSE movconcepto END as movconcepto
         ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'Efectivo' ELSE 'CTa.Cte' END as formapago
         ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'sepago' ELSE estadocuota END as estadocuota
         ,concat(persona.nombres , ' ' , persona.apellido) as nomape
         ,persona.nrodoc
         ,persona.barra
         ,CASE WHEN cte.idconsumoturismoestadotipos = 3 THEN 'Anulado' ELSE 'Vigente' END as estadoconsumo
         ,CASE WHEN nullvalue(facturas) THEN 'Sin Facturas' ELSE facturas END as infofacturas
         ,movconceptopago,infopago
         FROM consumoturismo
         NATURAL JOIN consumoturismoestado cte
         NATURAL JOIN prestamo
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
                  SELECT d.fechamovimiento as fechadeudactacte, d.idcomprobante,d.idconcepto,d.idcomprobantetipos, CASE WHEN nullvalue(p.iddeuda) THEN 'sedebe' ELSE 'sepago' END as estadocuota
,d.movconcepto, p.importeimp,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,p.fechamovimiento as fechapago
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
                 WHERE  (fechamovimiento >= $2 AND fechamovimiento <= $1)
                 GROUP BY iddeuda,idcentrodeuda
           )as p USING (iddeuda,idcentrodeuda)
WHERE d.idcomprobantetipos = 7
) as ctacte ON ctacte.idcomprobante = pc.idprestamocuotas * 10 + pc.idcentroprestamocuota
				AND ctacte.idcomprobantetipos = pc.idcomprobantetipos
WHERE nullvalue(cte.ctefechafin)-- AND nullvalue(pcborrado) 


) as t

WHERE (   (fechamovimiento >= $2 AND fechamovimiento <= $1)
            OR(   estadocuota ilike 'sepago' ) AND (fechapago >= $2 AND fechapago <= $1 )
      )
AND ($3 = '' OR  estadocuota = $3 )
$function$
