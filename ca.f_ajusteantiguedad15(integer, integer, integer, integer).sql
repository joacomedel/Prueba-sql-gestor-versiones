CREATE OR REPLACE FUNCTION ca.f_ajusteantiguedad15(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;

       recconact record;
       recconant record;
       rconcepto record;
       difporcentaje DOUBLE PRECISION;
       elmontoactual DOUBLE PRECISION;
       elmontoanterior DOUBLE PRECISION;
       difmesesliq integer;
       elmesingreso integer;
      

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
 /*    codliquidacion = $1;
     eltipo = $2;
     idpersona =  $3;
     elidconcepto = $4;
     laformula = $5; */

   
     elmonto = 0;
     -- Busco el monto del concepto 1050
     SELECT INTO recconact *
     FROM ca.conceptoempleado
     NATURAL JOIN ca.liquidacion
     WHERE idconcepto = 1050 and  idpersona =$3 and idliquidacion= $1;
     
     
     -- Busco el de la liq anterior y comparo si los porcentajes del concepto son <>
     SELECT INTO recconant *
     FROM ca.conceptoempleado
     NATURAL JOIN ca.liquidacion
     WHERE idconcepto = 1050 and  idpersona =$3
           and (idliquidaciontipo= 2 and limes=(recconact.limes - 1) and lianio=(recconact.lianio))
           and  ceporcentaje <>  recconact.ceporcentaje;

     IF FOUND THEN
              --- 1 - calculo el importe del ajuste
              difporcentaje = recconact.ceporcentaje -  recconant.ceporcentaje;
              -- 2 - calculo la cantidad de meses
              SELECT INTO elmesingreso extract(month from emfechadesde)   FROM ca.empleado WHERE idpersona =$3;
              difmesesliq = recconact.limes - (elmesingreso+1) ;
                   -- esto no funciona si la cantidad de anios es mayor a 1
              IF difmesesliq <0 THEN
                 difmesesliq = 12 - abs( difmesesliq);
              END IF;
              
              elmontoactual =  ( recconact.ceporcentaje *  recconact.cemonto ) ;
              elmontoanterior =  ( recconant.ceporcentaje *  recconant.cemonto );
              elmonto = elmontoactual - elmontoanterior;
              -- 3 - inserto el concepto del ajuste
              SELECT INTO rconcepto * FROM ca.conceptoempleado WHERE idpersona =$3 and idliquidacion= $1 and idconcepto = 1207;
              IF FOUND THEN
                 UPDATE ca.conceptoempleado SET ceporcentaje = difmesesliq  ,  cemonto =elmonto
                 WHERE idpersona =$3 and idliquidacion= $1 and idconcepto = 1207;
              ELSE
                  INSERT INTO ca.conceptoempleado (cemonto,ceporcentaje,idliquidacion,idpersona,idconcepto,cefechamodificacion)
                  VALUES(elmonto,difmesesliq,$1,$3,1207,now());
              END IF;
             
     END IF;

     return elmonto ;
  --elmonto*0.5;
END;
$function$
