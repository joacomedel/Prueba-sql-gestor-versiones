CREATE OR REPLACE FUNCTION ca.conceptovalor(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE

     elmes integer;
     elidpersona integer;
     elanio integer;
     elidconcepto integer;
     monto double precision;
     info varchar;
BEGIN
     elmes = $1;
     elanio = $2;
     elidpersona = $3;
      elidconcepto = $4;

     -- $4 = mf (monto final)
     -- $4 = p (porcentaje concepto)
     -- $4 = m (monto concepto)


     SELECT INTO monto
             (ceporcentaje * cemonto)
     FROM ca.conceptoempleado
     natural join ca.liquidacion
     WHERE  limes = elmes
                                 and lianio = elanio
                                 and idpersona = elidpersona
                                 and idconcepto = elidconcepto ;

     IF nullvalue(monto) THEN monto=0; END IF;

return round( monto::numeric,2 ) ;


END;
$function$
