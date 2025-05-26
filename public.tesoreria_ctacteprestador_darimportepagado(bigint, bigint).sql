CREATE OR REPLACE FUNCTION public.tesoreria_ctacteprestador_darimportepagado(bigint, bigint)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

--$1 idtipocomprobante de pago, $2 idprestadorctacte

	rpagos RECORD;
        vimportepaga double precision;
                          
BEGIN
vimportepaga = 0;

 SELECT INTO rpagos idcomprobante,idprestadorctacte,sum(importe) as importepaga FROM (
SELECT p.idcomprobante,p.idprestadorctacte,d.idcomprobante as idcomprobantedeuda,d.fechamovimiento,d.movconcepto,d.importe,dp.importeimp,abs(d.saldo) as saldo,2 as orden
FROM ctactepagoprestador as p
JOIN  ctactedeudapagoprestador as dp using(idpago,idcentropago)
JOIN ctactedeudaprestador as d using(iddeuda,idcentrodeuda)
LEFT JOIN reclibrofact as rf ON (  ( (rf.numeroregistro*10000)+rf.anio)= d.idcomprobante)
WHERE  p.idcomprobante=$1
           AND idtipocomprobante  <>3
UNION
SELECT p.idcomprobante,p.idprestadorctacte,d.idcomprobante as idcomprobantedeuda,d.fechamovimiento ,concat(rf.tipofactura,'-',rf.letra,rf.numero,d.movconcepto , ': ') , f.fimportetotal,f.fimportepagar,0 as saldo,2 as orden
FROM ctactepagoprestador as p
JOIN  ctactedeudapagoprestador as dp using(idpago,idcentropago)
JOIN ctactedeudaprestador as d using(iddeuda,idcentrodeuda)
JOIN factura as f ON(d.idcomprobante = ((idresumen*10000 )+ anioresumen  ) )
JOIN reclibrofact as rf ON (nroregistro = numeroregistro AND  f.anio = rf.anio)
WHERE  p.idcomprobante=$1
and d.idcomprobantetipos = 49
UNION
SELECT p.idcomprobante,p.idprestadorctacte,idcomprobante as idcomprobantedeuda,fechamovimiento,movconcepto,importe,0,saldo ,1 as orden
FROM ctactedeudapagoprestador as dp
JOIN  (
      SELECT iddeuda,idcentrodeuda
      FROM ctactepagoprestador as p
      JOIN  ctactedeudapagoprestador as dp using(idpago,idcentropago)
      JOIN ctactedeudaprestador as d using(iddeuda,idcentrodeuda)
      WHERE    p.idcomprobante=$1
)as lasd using (iddeuda,idcentrodeuda)
join ctactepagoprestador as p    using(idpago,idcentropago)
WHERE idcomprobante<>$1
and importe <> 0
group by  p.idcomprobante,p.idprestadorctacte,p.idcomprobante,fechamovimiento,movconcepto,importe,saldo
order by orden
) as t
GROUP BY idcomprobante,idprestadorctacte;

IF FOUND THEN 
	vimportepaga = rpagos.importepaga;
END IF;
return vimportepaga;

END;$function$
