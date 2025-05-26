CREATE OR REPLACE FUNCTION ca.conceptovalorsac(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

     elmes integer;
     elidpersona integer;
     elanio integer;
     monto double precision;
     info varchar;
BEGIN
     elmes = $1;
     elanio = $2;
     elidpersona = $3;
    
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
                                 and (idconcepto=32 or idconcepto=1092);

     IF nullvalue(monto) THEN monto=0; END IF;
     
return round( monto::numeric,3 ) ;


END;
$function$
