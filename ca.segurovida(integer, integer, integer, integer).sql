CREATE OR REPLACE FUNCTION ca.segurovida(integer, integer, integer, integer)
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
  
    
             
      /*SELECT INTO datoaux    (ceporcentaje * cemonto) as valor
      FROM ca.conceptoempleado     natural join ca.liquidacion
      WHERE  idliquidacion=$1    and idpersona = elidpersona   and (idconcepto=993); 
      
   if found then 
       valoraux=0.5;
               else*/
 valoraux=1;
      --end if;

      --calcula el bruto
      SELECT into montobruto ca.f_bruto(rsliquidacion.idliquidacion,0,elidpersona,0);
      
    if found then 
                -- if    montobruto>80000 then valorseguro=valoraux*1600;
                 --  if    montobruto>125000 then valorseguro=valoraux*2500;
              --  if    montobruto>285000 then valorseguro=valoraux*5700;
              --    if    montobruto>300000 then valorseguro=valoraux*6000;
/*
Si el sueldos bruto de la persona es mayor a $1.500.000 corresponde que el valor de ese concepto 987 sea $30000 y si la persona tiene además el 993 (cónyuge) que el valor sea el 0.5 del 987 ósea $15000
Si el total bruto de la persona es menor a $1.500.000 corresponde el siguiente cálculo= total bruto x 20 x 0.0007
y si la persona tiene además el 993 corresponde el 0.5 de 987 que varía según ese monto.
*/
               --  if    montobruto>1500000 then valorseguro=valoraux*30000;
            --Dani remplazo 23012024
               --  if    montobruto>3750000 then valorseguro=valoraux*67500;
              --Dani remplazo 20-09-2024
                   if    montobruto>3750000 then valorseguro=valoraux*75000;


                                     --   else valorseguro=valoraux*montobruto*20*0.001;
                else valorseguro=valoraux*montobruto*20*0.0007;

                 end if;
    end if; 
   

end if;
monto=valorseguro;

return round( monto::numeric,3 ) ;
END;
$function$
