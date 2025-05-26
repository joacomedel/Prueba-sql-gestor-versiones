CREATE OR REPLACE FUNCTION ca.segurovida993(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

     elmes integer;
     elidpersona integer;
     elanio integer;
     monto double precision;
     valorseguro double precision;
     montobruto double precision;
     valoraux double precision;
     /*info varchar;*/
     eltipo integer;
     rsliquidacion record;
     datoaux record;
BEGIN
     elmes = $1;
     elanio = $2;
     elidpersona = $3;
     eltipo =$4;
    /*
     codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;
*/
   SELECT INTO rsliquidacion * FROM ca.liquidacion WHERE idliquidacion=$1;
if Found then
  
    
             
      SELECT INTO datoaux    (ceporcentaje * cemonto) as valor
      FROM ca.conceptoempleado     natural join ca.liquidacion
      WHERE  idliquidacion=$1    and idpersona = elidpersona   and (idconcepto=987); 
      
     if found then 
          valorseguro=1*datoaux.valor;
          else valorseguro=0;
      end if;

     
      


end if;
monto=valorseguro;

return round( monto::numeric,3 ) ;
END;
$function$
