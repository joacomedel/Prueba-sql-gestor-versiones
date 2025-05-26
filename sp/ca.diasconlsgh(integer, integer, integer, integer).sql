CREATE OR REPLACE FUNCTION ca.diasconlsgh(integer, integer, integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       liq record;
       rangofechalsgh record;
       cantdias INTEGER;
       /*cantdiaslsgh INTEGER;*/
       valor integer;
       tienelic boolean;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     --f_funcion(#,&, ?,@)

    /*  cantdiaslsgh=0;*/
      valor=0;
      

      SELECT INTO liq * FROM ca.liquidacion WHERE idliquidacion = $1;

      select into tienelic from ca.licencia
      natural join ca.licenciatipo
      where 
             idlicenciatipo=26 and   liq.lianio>=extract (year from (lifechainicio)) 
             and liq.lianio <= extract (year from(lifechafin))      
             and idpersona =$3 ;

      if found then


           if (liq.idliquidaciontipo=1 or liq.idliquidaciontipo=2 )then
               /*Dani agrego el 2019-06-28 para  q sume todos los dias de todas las posibles licencias de tipo 26*/
               /*select into rangofechalsgh*/
               select into valor sum (cant)
               from (
                    select *,((fechafin-fechainicio)+1)as cant
                    from  (   select  idlicencia,
                              case when ((concat(liq.lianio ,'-',liq.limes,'-01'))::date >=lifechainicio::date)      then concat(liq.lianio,'-',liq.limes,'-01')::date
                                        else lifechainicio::date end as fechainicio
                                        ,case when ((date_trunc('month', (concat(liq.lianio ,'-',liq.limes,'-1'))::date ) + interval '1 month') - interval '1 day')::date <=lifechafin
    
                                        then ((date_trunc('month', (concat(liq.lianio ,'-',liq.limes,'-1'))::date ) + interval '1 month') - interval '1 day')::date
                                        else lifechafin::date

                               end as fechafin
                               from ca.licencia
                               natural join ca.licenciatipo
                               where
                                    idlicenciatipo=26
                                   
                                     and  concat(liq.lianio ,'-',liq.limes,'-01')::date <= lifechafin::date 
                                    and idpersona =$3
                 )as g
                 group by idlicencia,fechafin,fechainicio
                 ) as g;

else /*si es de tipo aguinaldo*/


 select into valor sum (cant)
               from (
                    select *,((fechafin-fechainicio)+1)as cant
                    from  (    select idlicencia,
                        case when ((concat(liq.lianio,'-01','-01'))::date >=lifechainicio::date)  and liq.limes=6    then concat(liq.lianio,'-01','-01')::date  
                             else  case when liq.limes=6 then  lifechainicio::date 
                             else  case when ((concat(liq.lianio ,'-07','-01'))::date >=lifechainicio::date)  and liq.limes=12    
                             then concat(liq.lianio,'-07','-01')::date  
                             else  case when liq.limes=12 then  lifechainicio::date              
                             end end end end as fechainicio,

                             case when  ((concat(liq.lianio,'-07','-01')::date  + interval '1 month') - interval '1 day')::date <=lifechafin::date
                              and liq.limes=6  then ((concat(liq.lianio,'-06','-01')::date   + interval '1 month') - interval '1 day')::date
                              else  case when liq.limes=6  then lifechafin::date
                              else  case when ((concat(liq.lianio ,'-07','-01'))::date >=lifechafin::date)  and liq.limes=12    
                               then concat(liq.lianio,'-06','-01')::date  

          else  case when ((concat(2023 ,'-12','-31'))::date <lifechafin::date)  AND 12=12        then concat(2023 ,'-12','-31')::date  
                 
          else  case when ((concat(2023 ,'-12','-31'))::date >=lifechafin::date) AND liq.limes=12 then lifechafin::date  

                     end     end end end end as   fechafin
                               from ca.licencia
                               natural join ca.licenciatipo
                               where
                                    idlicenciatipo=26                                    
                                     and  concat(liq.lianio ,'-01','-01')::date <=  lifechafin::date
                                     and idpersona =$3
                 )as g
                 group by idlicencia,fechafin,fechainicio
                 ) as g;


end if;/*f (liq.idliquidaciontipo=1 or liq.idliquidaciontipo=2 )*/



      end if;/*if found then*/


      if nullvalue(valor) or (valor <0) then
         valor = 0;      
      END IF;


      return valor;
END;
$function$
