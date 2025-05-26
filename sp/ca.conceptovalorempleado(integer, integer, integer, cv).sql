CREATE OR REPLACE FUNCTION ca.conceptovalorempleado(integer, integer, integer, character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE

     elidliquidacion integer;
     elidpersona integer;
     elidconcepto integer;
     monto double precision;
     info varchar;
BEGIN
     elidliquidacion = $1;
     elidpersona = $2;
     elidconcepto = $3;
     info = $4;
     -- $4 = mf (monto final)
     -- $4 = p (porcentaje concepto)
     -- $4 = m (monto concepto)


     SELECT INTO monto
            CASE WHEN (info = 'mf') THEN  (ceporcentaje * cemonto)
                 WHEN (info = 'p') THEN  ceporcentaje
                 WHEN (info = 'm') THEN  cemonto
            END

     FROM ca.conceptoempleado
     WHERE idconcepto = elidconcepto
                                 and idliquidacion = elidliquidacion
                                 and idpersona = elidpersona;
     IF nullvalue(monto) THEN monto=0; END IF;
     
return round( monto::numeric,2 ) ;


END;
$function$
