CREATE OR REPLACE FUNCTION ca.redondeoconceptos(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE
       elidpersona integer;
       elidconcepto integer;
       elidliquidacion integer;
       rsliquidacion  record;
       rcategoriaempleado record;
       valor double precision;  
       rconceptoempleado record;
       rhorasasigandas record;
       datolicencia record;
       tienelicencia boolean;


BEGIN
     elidpersona = $1;  -- la persona
     elidconcepto = $2; -- el concepto
     elidliquidacion = $3; -- la liquidacion
     valor=0;
     tienelicencia=false;

     SET search_path = ca, pg_catalog;
     /* Verifico la existencia de una liquidacion para ese mes y ese anio*/

     SELECT INTO rsliquidacion * FROM liquidacion WHERE  idliquidacion=elidliquidacion;


 /*obtengo el monto basico para la categoria de esa persona*/ 
     /*SELECT INTO rcategoriaempleado min(idcategoria) as idcategoria,idpersona,camonto 
      from ca.categoriaempleado
      natural join  ca.categoriatipoliquidacion
      where   idcategoriatipo=1
      and idpersona=elidpersona
      and(nullvalue(cefechafin) or  
      (concat(rsliquidacion.lianio,'-',rsliquidacion.limes,'-01'))::date  <=cefechafin )

      group by idpersona,camonto;
*/
        SELECT  INTO rcategoriaempleado 
        case   when  (round((ceporcentaje*cemonto)::numeric) -
               round((ceporcentaje*cemonto)::numeric,2) )  >= 0.01 
        AND  (round((ceporcentaje*cemonto)::numeric) - round((ceporcentaje*cemonto)::numeric,2) )
                 <= 0.02 then round((ceporcentaje*cemonto)::numeric)
        else
        round((ceporcentaje*cemonto)::numeric,2) end as valor 

        from   ca.conceptoempleado  
                 WHERE idpersona = elidpersona
                 AND idliquidacion = elidliquidacion 
                 AND (idconcepto = 1 or idconcepto=1028);
     IF  FOUND THEN
         
      /*Esto es para resolver el problema de redondeo q no quieren q aparezca en los reportes de sueldos*/
                 
           SELECT INTO rconceptoempleado * from   ca.conceptoempleado  
         WHERE idpersona = elidpersona
         AND idliquidacion = elidliquidacion 
         AND idconcepto = elidconcepto;
          IF  FOUND THEN
              /*Busco la cantidad de horas asignadas a la jornada*/
        
               SELECT INTO rhorasasigandas * from   ca.conceptoempleado  
                 WHERE idpersona = elidpersona
                 AND idliquidacion = elidliquidacion 
                 AND idconcepto = 100;
            /*Busco si laperosna tiene una licencia por maternidad*/
        
                 SELECT INTO datolicencia  * from   ca.conceptoempleado  
                 WHERE idpersona = elidpersona
                 AND idliquidacion = elidliquidacion 
                 AND idconcepto = 1105;
                    IF  FOUND THEN
                      tienelicencia=true;
                      else
                      tienelicencia=false;
                     end if;
  /* si se trata del basico y si ademas la persona trabaja la jornada completa y si la   
                 persona  NO TIENE  una licencia por maternidad*/
           
                 if (   ( elidconcepto=1028 or ( elidconcepto=1 and rconceptoempleado.ceporcentaje=30)) and 
                         rhorasasigandas.cemonto=rhorasasigandas.ceunidad) and (NOT tienelicencia) then 
                  valor=rcategoriaempleado.valor;
                 
                 else
                     if (      (round((rconceptoempleado.ceporcentaje*rconceptoempleado.cemonto)::numeric) -
                 round((rconceptoempleado.ceporcentaje*rconceptoempleado.cemonto)::numeric,2) )  >= 0.01 AND
                 (round((rconceptoempleado.ceporcentaje*rconceptoempleado.cemonto)::numeric) - round((rconceptoempleado.ceporcentaje*rconceptoempleado.cemonto)::numeric,2) )
                 <= 0.02 AND (elidconcepto<>989 and elidconcepto<>1170))   THEN 
                                   valor=round((rconceptoempleado.ceporcentaje*rconceptoempleado.cemonto)::numeric);
                 else
                            valor=round((rconceptoempleado.ceporcentaje*rconceptoempleado.cemonto)::numeric,2) ;
               end if;      
                 end if;             
--Si la liquidaicon esta abierta
if (nullvalue(rsliquidacion.lifecha ))
then
update ca.conceptoempleado set cemontofinal = valor  
                 WHERE idpersona = elidpersona
                       AND idliquidacion = elidliquidacion 
                       AND idconcepto = elidconcepto ;
 END IF;
          END IF;
          
     END IF;

return 	valor;
END;
$function$
