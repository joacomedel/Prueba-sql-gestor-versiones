CREATE OR REPLACE FUNCTION public.movimientosctacteasistencial(date, date, character varying)
 RETURNS SETOF movimientoctacteasistencial
 LANGUAGE sql
AS $function$SELECT
max(fechamovimiento)::varchar as fechainimov
,null::integer as idconcepto
,sum(CASE WHEN nullvalue(importedeuda) THEN importedeuda ELSE importedeuda END) as importedeuda
,sum(CASE WHEN nullvalue(importepagado) THEN importepagado ELSE importepagado END) as importepagado
,null::varchar as fechapagoprobable
,null::varchar as fechapago
,null::bigint as iddeuda
,null::integer as idcentrodeuda
,null::varchar as movconcepto
,null::varchar as formapago
,null::varchar as estadocuota
,null::varchar as nomape
,null::varchar as nrodoc
,null::varchar as barra
,null::varchar as estadoconsumo
,'Sin Facturas'::varchar as infofacturas
,null::varchar as movconceptopago
,null::varchar as infopago

FROM (
     SELECT importeimp, fechaemision as fechamovimiento
     ,CASE WHEN nullvalue(importedeuda) THEN importecuota ELSE importedeuda END as importedeuda
     ,CASE WHEN nullvalue(importeimp) THEN
	       CASE WHEN nullvalue(ctacte.idcomprobante) THEN importecuota
           ELSE 0 END
     ELSE importeimp END as importepagado
     ,ctacte.fechapago as fechapagoprobable
      ,ctacte.fechapago
      ,iddeuda,idcentrodeuda,idconcepto
      ,CASE WHEN nullvalue(movconcepto) THEN concat('Consumo Orden ',nroorden , '-' , centro) ELSE movconcepto END as movconcepto
      ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'Efectivo' ELSE 'CTa.Cte' END as formapago
      ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'sepago' ELSE estadocuota END as estadocuota
      ,concat(persona.nombres , ' ' , persona.apellido) as nomape
      ,persona.nrodoc
      ,persona.barra
      ,CASE WHEN nullvalue(fechacambio) THEN 'Vigente' ELSE 'Anulado' END as estadoconsumo
      ,CASE WHEN nullvalue(facturas) THEN 'Sin Facturas' ELSE facturas END as infofacturas
      ,movconceptopago,infopago
      ,elsaldo
       FROM   orden
       LEFT JOIN ordenestados using (nroorden,centro)
       NATURAL JOIN  (SELECT SUM(importe) as importecuota,nroorden , centro
                      FROM  importesorden
                      WHERE idformapagotipos <>6
                      group by nroorden , centro ) as importeorden
       LEFT JOIN (
                 SELECT orden.nroorden , orden.centro , text_concatenar(concat(facturaventa.fechaemision , ' ' ,facturaventa.tipofactura,' ' , nrosucursal,'-',nrofactura,' imp.efc $',importeefectivo,' imp.ctacte $',importectacte)) as facturas
                 FROM  facturaventa
                 JOIN facturaorden using ( nrofactura , nrosucursal)
                 JOIN orden ON (orden.nroorden=facturaorden.nroorden and orden.centro = facturaorden.centro)
                 group by orden.nroorden,orden.centro
           ) as facturasqueseusaron USING(nroorden , centro)
       LEFT JOIN ( -- info deuda
                 SELECT   d.idcomprobante,d.idconcepto,d.idcomprobantetipos,
                     CASE WHEN (d.importe - CASE WHEN nullvalue(p.importeimp) THEN 0 ELSE p.importeimp END = 0)  THEN 'sepago' ELSE  'sedebe' END as estadocuota,
                     d.importe - CASE WHEN nullvalue(p.importeimp) THEN 0 ELSE p.importeimp END  as elsaldo ,
                     d.movconcepto, p.importeimp,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,
                     p.fechamovimiento as fechapago
                     ,p.movconceptopago,p.infopago,d.tipodoc ,d.nrodoc
                FROM cuentacorrientedeuda as d
                 LEFT JOIN (
                       -- Comienza la consulta de los pagos
                       SELECT iddeuda,idcentrodeuda,sum(importeimp) as importeimp,max(fechamovimiento) as fechamovimiento
			               ,text_concatenar(infopago) as infopago,text_concatenar(concat(movconcepto , ' ')) as movconceptopago
                       FROM cuentacorrientepagos
			           LEFT JOIN cuentacorrientedeudapago  USING (idpago,idcentropago)
			           LEFT JOIN (
                            SELECT idpago,idcentropago
						           ,text_concatenar(concat('F.Informe ' ,inf.fechainforme , ' Nro.Informe ' , i.nroinforme , '-' , i.idcentroinformefacturacion , ' F.D ' ,  i.fechadesde , ' F.H ' , i.fechahasta)) as infopago
   			                FROM informefacturacioncobranza i
						    NATURAL JOIN  informefacturacion inf
						    NATURAL JOIN informefacturacionestado ife
						    WHERE  nullvalue(ife.fechafin) AND ife.idinformefacturacionestadotipo = 8
						    GROUP BY idpago,idcentropago
            		 ) infopagos USING(idpago,idcentropago)
                     WHERE fechamovimiento < $2
                           -- and fechamovimiento <= '2012-12-31'
                     GROUP BY iddeuda,idcentrodeuda
               )as p USING (iddeuda,idcentrodeuda)  -- fin  la consulta de los pagos
               WHERE  d.fechamovimiento < $2
                      -- and d.fechamovimiento <= '2012-12-31'
                      -- and  abs(d.importe - p.importeimp) > 0
                      and tipodoc<100
      ) as ctacte ON (ctacte.idcomprobante = orden.nroorden * 100 + orden.centro
         				AND ctacte.idcomprobantetipos = orden.tipo)
       NATURAL JOIN persona
) as D
--WHERE elsaldo > 1
UNION
SELECT
fechamovimiento::varchar
,idconcepto,importedeuda,importepagado,fechapagoprobable::varchar,fechapago::varchar,iddeuda,idcentrodeuda
,movconcepto,formapago,estadocuota,nomape,nrodoc,barra::VARCHAR,
estadoconsumo,infofacturas,movconceptopago,infopago
--SELECT SUM(elsaldo)
FROM (
    SELECT importeimp, fechaemision as fechamovimiento
     ,CASE WHEN nullvalue(importedeuda) THEN importecuota ELSE importedeuda END as importedeuda
     ,CASE WHEN nullvalue(importeimp) THEN
	       CASE WHEN nullvalue(ctacte.idcomprobante) THEN importecuota
           ELSE 0 END
     ELSE importeimp END as importepagado
     ,ctacte.fechapago as fechapagoprobable
      ,ctacte.fechapago
      ,iddeuda,idcentrodeuda,idconcepto
      ,CASE WHEN nullvalue(movconcepto) THEN concat('Consumo Orden ',nroorden , '-' , centro) ELSE movconcepto END as movconcepto
      ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'Efectivo' ELSE 'CTa.Cte' END as formapago
      ,CASE WHEN nullvalue(ctacte.idcomprobante) THEN 'sepago' ELSE estadocuota END as estadocuota
      ,concat(persona.nombres , ' ' , persona.apellido) as nomape
      ,persona.nrodoc
      ,persona.barra
      ,CASE WHEN nullvalue(fechacambio) THEN 'Vigente' ELSE 'Anulado' END as estadoconsumo
      ,CASE WHEN nullvalue(facturas) THEN 'Sin Facturas' ELSE facturas END as infofacturas
      ,movconceptopago,infopago
      ,elsaldo
       FROM   orden
       LEFT JOIN ordenestados using (nroorden,centro)
       NATURAL JOIN  (SELECT SUM(importe) as importecuota,nroorden , centro
                      FROM  importesorden
                      WHERE idformapagotipos <>6
                      group by nroorden , centro ) as importeorden
       LEFT JOIN (
                 SELECT orden.nroorden , orden.centro , text_concatenar(concat(facturaventa.fechaemision , ' ' ,facturaventa.tipofactura,' ' , nrosucursal,'-',nrofactura,' imp.efc $',importeefectivo,' imp.ctacte $',importectacte)) as facturas
                 FROM  facturaventa
                 JOIN facturaorden using ( nrofactura , nrosucursal)
                 JOIN orden ON (orden.nroorden=facturaorden.nroorden and orden.centro = facturaorden.centro)
                 group by orden.nroorden,orden.centro
           ) as facturasqueseusaron USING(nroorden , centro)
       LEFT JOIN ( -- info deuda
                 SELECT   d.idcomprobante,d.idconcepto,d.idcomprobantetipos,
                     CASE WHEN (round(d.importe::numeric ,2) - CASE WHEN nullvalue(p.importeimp) THEN 0 ELSE p.importeimp END = 0)  THEN 'sepago' ELSE  'sedebe' END as estadocuota,
                     round(d.importe::numeric ,2) - CASE WHEN nullvalue(p.importeimp) THEN 0 ELSE p.importeimp END  as elsaldo ,
                     d.movconcepto, p.importeimp,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,
                     p.fechamovimiento as fechapago
                     ,p.movconceptopago,p.infopago,d.tipodoc ,d.nrodoc

                --SELECT *
                 FROM cuentacorrientedeuda as d
                 LEFT JOIN (
                       -- Comienza la consulta de los pagos
                       SELECT iddeuda,idcentrodeuda,round (sum(importeimp)::numeric ,2 )as importeimp,max(fechamovimiento) as fechamovimiento
			               ,text_concatenar(infopago) as infopago,text_concatenar(concat(movconcepto , ' ')) as movconceptopago

                       FROM cuentacorrientepagos
			           LEFT JOIN cuentacorrientedeudapago  USING (idpago,idcentropago)
			           LEFT JOIN (
                            SELECT idpago,idcentropago
						           ,text_concatenar(concat('F.Informe ' ,inf.fechainforme , ' Nro.Informe ' , i.nroinforme , '-' , i.idcentroinformefacturacion , ' F.D ' ,  i.fechadesde , ' F.H ' , i.fechahasta)) as infopago
   			                FROM informefacturacioncobranza i
						    NATURAL JOIN  informefacturacion inf
						    NATURAL JOIN informefacturacionestado ife
						    WHERE  nullvalue(ife.fechafin) AND ife.idinformefacturacionestadotipo = 8
						    GROUP BY idpago,idcentropago
            		 ) infopagos USING(idpago,idcentropago)
                     WHERE fechamovimiento >=  $2 and
                           fechamovimiento <= $1
                     GROUP BY iddeuda,idcentrodeuda
               )as p USING (iddeuda,idcentrodeuda)  -- fin  la consulta de los pagos
               WHERE  d.fechamovimiento >= $2 and
                      d.fechamovimiento <= $1
                      --and  abs(d.importe - p.importeimp) > 0
                      and tipodoc<100
      ) as ctacte ON (ctacte.idcomprobante = orden.nroorden * 100 + orden.centro
         				AND ctacte.idcomprobantetipos = orden.tipo)
       NATURAL JOIN persona
) as D
UNION 

SELECT fechamovimiento::varchar ,idconcepto,importedeuda,importepagado,fechapagoprobable::varchar,fechapago::varchar,iddeuda,idcentrodeuda
,movconcepto,formapago,estadocuota,nomape,nrodoc,barra::VARCHAR,estadoconsumo,infofacturas,movconceptopago,infopago
--SELECT SUM(elsaldo)
FROM (
SELECT importeimp, fechaemision as fechamovimiento
     ,CASE WHEN nullvalue(importedeuda) THEN (importectacte)ELSE importedeuda END as importedeuda
     ,CASE WHEN nullvalue(importeimp) THEN
	       CASE WHEN nullvalue(ctactefa.idcomprobante) THEN importectacte
           ELSE 0 END
     ELSE importeimp END as importepagado
     ,ctactefa.fechapago as fechapagoprobable
      ,ctactefa.fechapago
      ,iddeuda,idcentrodeuda,idconcepto
      ,movconcepto
      ,CASE WHEN nullvalue(ctactefa.idcomprobante) THEN 'Efectivo' ELSE 'CTa.Cte' END as formapago
      ,CASE WHEN nullvalue(ctactefa.idcomprobante) THEN 'sepago' ELSE estadocuota END as estadocuota
      ,concat(persona.nombres , ' ' , persona.apellido) as nomape
      ,persona.nrodoc
      ,persona.barra
      ,CASE WHEN nullvalue(anulada) THEN 'Vigente' ELSE 'Anulado' END as estadoconsumo
      ,CASE WHEN nullvalue(concat(fv.fechaemision , ' ' ,fv.tipofactura,' ' , fv.nrosucursal,'-',fv.nrofactura,' imp.efc $',fv.importeefectivo,' imp.ctacte $',fv.importectacte)) THEN 'Sin Facturas' ELSE concat(fv.fechaemision , ' ' ,fv.tipofactura,' ' , fv.nrosucursal,'-',fv.nrofactura,' imp.efc $',fv.importeefectivo,' imp.ctacte $',fv.importectacte) END as infofacturas
      ,movconceptopago,infopago
      ,elsaldo


       FROM facturaventa fv join informefacturacion if using(tipofactura,nrosucursal,nrofactura,tipocomprobante )
  --     JOIN facturaorden fo on fv.nrofactura =fo.nrofactura and fv.nrosucursal=fo.nrosucursal 
       LEFT JOIN ( 
              SELECT   d.idcomprobante,d.idconcepto,d.idcomprobantetipos,
                    CASE WHEN (round(d.importe::numeric ,2) - CASE WHEN nullvalue(p.importeimp) THEN 0 ELSE p.importeimp END = 0)  THEN 'sepago' ELSE  'sedebe' END as estadocuota,
                     round(d.importe::numeric ,2) - CASE WHEN nullvalue(p.importeimp) THEN 0 ELSE p.importeimp END  as elsaldo ,
                     d.movconcepto, p.importeimp,d.iddeuda,d.idcentrodeuda,d.importe as importedeuda,
                     p.fechamovimiento as fechapago
                     ,p.movconceptopago,p.infopago,d.tipodoc ,d.nrodoc 
                --SELECT *
                 FROM cuentacorrientedeuda as d 
                 LEFT JOIN (
                       -- Comienza la consulta de los pagos
                       SELECT iddeuda,idcentrodeuda,round (sum(importeimp)::numeric ,2 )as importeimp,max(fechamovimiento) as fechamovimiento
			               ,text_concatenar(infopago) as infopago,text_concatenar(concat(movconcepto , ' ')) as movconceptopago

                       FROM cuentacorrientepagos
			           LEFT JOIN cuentacorrientedeudapago  USING (idpago,idcentropago)
			           LEFT JOIN (
                            SELECT idpago,idcentropago
						           ,text_concatenar(concat('F.Informe ' ,inf.fechainforme , ' Nro.Informe ' , i.nroinforme , '-' , i.idcentroinformefacturacion , ' F.D ' ,  i.fechadesde , ' F.H ' , i.fechahasta)) as infopago
   			                FROM informefacturacioncobranza i
						    NATURAL JOIN  informefacturacion inf
						    NATURAL JOIN informefacturacionestado ife
						    WHERE  nullvalue(ife.fechafin) AND ife.idinformefacturacionestadotipo = 8
						    GROUP BY idpago,idcentropago
            		 ) infopagos USING(idpago,idcentropago)
                  --   WHERE  fechamovimiento >= '2019-01-01' and                            fechamovimiento <= '2019-12-31'
                       WHERE fechamovimiento >=  $2 and
                           fechamovimiento <= $1 
                     GROUP BY iddeuda,idcentrodeuda
               )as p USING (iddeuda,idcentrodeuda)  -- fin  la consulta de los pagos
               WHERE    d.fechamovimiento >= $2 and
                      d.fechamovimiento <= $1
 
                      --and  abs(d.importe - p.importeimp) > 0
                      and d.tipodoc<100

      ) as ctactefa ON (ctactefa.idcomprobante=((if.nroinforme*100)+if.idcentroinformefacturacion)  )
      JOIN persona on persona.nrodoc= ctactefa.nrodoc and persona.tipodoc= ctactefa .tipodoc
) as DFA
 


WHERE ($3 = '' OR  estadocuota = $3);-- and nrodoc='35382177';$function$
