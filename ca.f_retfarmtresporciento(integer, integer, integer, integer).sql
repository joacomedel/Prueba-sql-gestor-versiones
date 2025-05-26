CREATE OR REPLACE FUNCTION ca.f_retfarmtresporciento(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        monto DOUBLE PRECISION;
        monto1 DOUBLE PRECISION;
        monto2 DOUBLE PRECISION;
        rliquidacion record;
        rcatemp  record;   
       
BEGIN
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     -- CONTROLAR QUE NO QUEDE EN 0 cuando se hacen los descuentos



monto1 = 0;	
monto2 = 0;	
monto = 0;	


     SELECT INTO rliquidacion * FROM ca.liquidacion   WHERE  idliquidacion= $1;

    
--Busco la categoria del empleado
 
SELECT into rcatemp idcategoria
    FROM ca.categoriaempleado
    natural JOIN ca.categoria
    WHERE idpersona =$3
          and idcategoriatipo = 1 
         and (
 date_trunc('month', concat(rliquidacion.lianio,'-',rliquidacion.limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)
        ) ;


if (rcatemp.idcategoria=18) then  --FARMACEUTICO AUXILIAR

 SELECT INTO monto1 sum(ctmontominimo)
      FROM ca.conceptotope     
      WHERE  (idconcepto=1263   )
        and nullvalue(ctfechahasta) and idcategoria=18;
 

select into monto2  sum(comonto) 
      FROM ca.concepto     
      WHERE  (idconcepto=1284);
 
monto=(monto1+monto2);






else



      SELECT INTO monto 
case when nullvalue(sum(ceporcentaje* cemonto)) then 0 else
sum(ceporcentaje* cemonto) end 
      FROM ca.conceptoempleado
      WHERE  idpersona=$3 and idliquidacion =$1
      and (idconcepto =1162    --Acta Acuerdo Paritaria Abril 2013
          or idconcepto=1169   --Comp.Extraor.08-2013 Claus. 4º AA
          or idconcepto=1185   --Acta Acuerdo Abril 2014-15
          or idconcepto=1191   --Comp. Extraor. Clausula Cuarta Acta Acuerdo 2014-2015
          or idconcepto=1199   --Acta Acuerdo Octubre 2015
          or idconcepto=1204   --Acta Acuerdo 2016/2017
          or idconcepto=1212   --Acta Acuerdo 2017/2018
/*Modificado el 28-10-19 por pedido de Julieta E*/
        --  or idconcepto=1235
          or idconcepto=1236    --Suma Ext. Salario devengado ENE 2019
          or idconcepto=1222    --Acta Acuerdo 2018/2019 
          or idconcepto=1231    --Ajuste Retroactivo SEP.2018
          or idconcepto=1178    --Ajuste "Acta Acuerdo Enero 2019"
--Dani agrego el 27042022 segun mail del dia de JE
          or idconcepto=1263    --Acta Acuerdo 2023 
      --Dani comento el 03082020 por pedido de Julieta E. segun acta acuerdo firmada el 31072020    or idconcepto=1242
or idconcepto=1226              --Comp. Extarord. Ene.2020 No Rem.
--Dani agrego el 17082020 por pedido de Julieta E. segun  mail
           or idconcepto=1278   --S.A.C. NO REM JULIO 2023
--Dani agrego el 22112022 por pedido de Julieta E. segun  chat
           or idconcepto=1253   --Bloqueo título Farm Director Técnico 2023
--Dani agrego el 22062023 por pedido de JE segun mail
           or idconcepto=1283   --Bloqueo al 80% título Farm Auxiliar 2023	
--Dani agrego el 22062023 por pedido de JE segun mail
           or idconcepto=1284   --Bloqueo al 60% título Farm Auxiliar 2023
 --Dani agrego el 25072023 por pedido de JE segun mail
  --  or idconcepto=1285   --Acta Paritaria Julio 2023
);
end if;

if (rcatemp.idcategoria=17) then  --FARMACEUTICO   
monto=monto--+11375.78
;
end if;



if (rcatemp.idcategoria=18) then  --FARMACEUTICO    AUXILIAR
monto=monto--+6825.56
;
end if;




return monto;
END;
$function$
