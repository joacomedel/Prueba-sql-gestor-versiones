CREATE OR REPLACE FUNCTION ca.diascomaternidad(integer, integer, integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       liq record;
       rangofechalsgh record;
       cantdias INTEGER;
       diastrabajados DOUBLE PRECISION;
       diaslicencia DOUBLE PRECISION;
       losdiaslab DOUBLE PRECISION;
       elidconcepto INTEGER;
       montototal INTEGER;
       rlicenciamaternidad record;
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

    
     montototal=0;
     valor=0;
SELECT INTO liq * FROM ca.liquidacion WHERE idliquidacion = $1;
/*Corroboro si es para una liquidacion de sueldo o de aguinaldo*/
if($2=1 or $2=2) then

              /* Corroboro si la persona esta con licencia por maternidad  CREAR FORMULA 1105 */
              SELECT INTO valor SUM(ceporcentaje)as  cant
	          FROM ca.conceptoempleado
              NATURAL JOIN ca.liquidacion
	          WHERE idpersona = $3    and	idconcepto = 1105
                    and lianio=extract(YEAR from CURRENT_DATE)
                    and limes > extract(MONTH from CURRENT_DATE)-6
                    and (idliquidaciontipo=1 or idliquidaciontipo=3);
else

    /*se calculan los dias de licencia por maternidad para el aguinaldo*/
    select into valor case when nullvalue(sum (cant)) then 0 else sum (cant) end as v
    from (
         select  *,((fechafin-fechainicio-1)+1)as cant
         from (   select idlicencia,
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
                            else  case when liq.limes=12 then  lifechafin::date  
                          end end end end as   fechafin
                 from ca.licencia
                 natural join ca.licenciatipo
                 where ( idlicenciatipo=73 or idlicenciatipo=33 or idlicenciatipo=99)
                      --  and  concat(liq.lianio ,'-',liq.limes,'-01')::date <=  lifechafin::date
                         and ( ((liq.limes=6 and concat(liq.lianio ,'-',1,'-01')::date <=  lifechafin::date)) or
                         ((liq.limes=12 and concat(liq.lianio ,'-',6,'-01')::date <=  lifechafin::date))        
                         ) 
                        and concat(liq.lianio ,'-',liq.limes,'-01')::date>=lifechainicio::date
                        and idpersona =$3
         )as g
         group by idlicencia,fechafin,fechainicio
    ) as g;
valor =(30*div(valor,30))+mod(valor,30);
end if;


      
return abs(valor);

END;
$function$
