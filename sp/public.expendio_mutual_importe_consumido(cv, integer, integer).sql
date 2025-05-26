CREATE OR REPLACE FUNCTION public.expendio_mutual_importe_consumido(character varying, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE      
--VARIABLES    
    totalconsumido DOUBLE PRECISION;
    tieneamuc BOOLEAN;
    elidmutualpadron BIGINT;
--REGISTROS
    lapersona RECORD;
    tienemutualp RECORD;
BEGIN

  
 
  SELECT INTO totalconsumido  SUM(CASE WHEN nullvalue(monto) THEN 0  WHEN (fv.tipofactura='NC') THEN monto*-1 ELSE monto END) /*facturaventa.nrodoc,facturaventa.tipodoc ,idobrasocial,idvalorescajafactura,sum(monto) as importeusado*/
		 FROM facturaventa  AS fv NATURAL JOIN facturaventacupon 
		 LEFT JOIN mutualpadron ON (idvalorescaja=idvalorescajafactura OR nullvalue(idvalorescajafactura))
		 AND fv.nrodoc = mutualpadron.nrodoc 
		 WHERE  fechaemision >= DATE_TRUNC('month',current_date) 
		 AND fechaemision <= (date_trunc('month', current_date) + '1month'::interval)::date 
		 AND  nullvalue(anulada) AND idvalorescaja = $3 AND fv.nrodoc = $1 AND fv.tipodoc=$2 
		 GROUP BY fv.nrodoc,fv.tipodoc ,idobrasocial,idvalorescajafactura;

IF nullvalue(totalconsumido) THEN
   totalconsumido = 0;

END IF;

return totalconsumido;

END$function$
