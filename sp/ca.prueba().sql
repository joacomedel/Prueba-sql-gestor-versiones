CREATE OR REPLACE FUNCTION ca.prueba()
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE
  rconceptoempleado record;
BEGIN
select into rconceptoempleado*,ca.redondeoconceptos(idpersona,idconcepto,idliquidacion) as monto
from
ca.conceptoempleado
NATURAL JOIN ca.concepto
NATURAL JOIN ca.liquidacion
WHERE


(limes>=9 and limes<=9 and lianio>=2015 and lianio<=2015  )
and (ca.conceptoempleado.idpersona=0 or 0=0 )
and idliquidaciontipo=2
and (ceporcentaje <> 0)
and (cemonto  <>0)
and cimprime
and idconceptotipo <>9
order by idliquidacion,idpersona::bigint,coorden,idconcepto;
return 0;
END;

$function$
