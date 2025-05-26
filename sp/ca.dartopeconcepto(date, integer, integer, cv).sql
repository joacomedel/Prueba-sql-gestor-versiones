CREATE OR REPLACE FUNCTION ca.dartopeconcepto(date, integer, integer, character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

     elmes integer;
     elidpersona integer;
     elanio integer;
     elidconcepto integer;
     monto double precision;
     info varchar;
lafecha date;
BEGIN
     lafecha = $1;
     elidconcepto = $2;
     elidpersona = $3;
      elidconcepto = $4;

   


     SELECT INTO monto
             (ceporcentaje * cemonto)
     FROM ca.conceptotpe
      
     WHERE  limes = elmes
                                 and lianio = elanio
                                 and idpersona = elidpersona
                                 and idconcepto = elidconcepto ;

     IF nullvalue(monto) THEN monto=0; END IF;

return round( monto::numeric,2 ) ;


END;
$function$
