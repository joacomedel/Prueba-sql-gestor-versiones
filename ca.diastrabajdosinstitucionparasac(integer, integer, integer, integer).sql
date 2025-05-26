CREATE OR REPLACE FUNCTION ca.diastrabajdosinstitucionparasac(integer, integer, integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       liq record;
       rangofechalsgh record;
       datocateg  record;
       datoaux1  record;
       datoaux2  record;
       datoaux3  record;
       cantdias INTEGER;
       cantdiaslsgh INTEGER;
       tienelic boolean;
       fechafinnueva date;
       fechainicionueva date; 

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/
     --f_funcion(#,&, ?,@)
cantdias=0;



     SELECT INTO liq * FROM ca.liquidacion WHERE idliquidacion = $1;
     select into datocateg * 
     from ca.categoriaempleado 
     where idcategoriatipo=1 
           and idpersona= $3 
           AND idcategoria <> 21  -- las pasantias no se tienen en cuenta para el SAC 
     order by cefechainicio  desc limit 1;
     
     --Para el caso de pasantes no corresponde aguinaldo
	 
     if (datocateg.idcategoria<>21) then 
              --RAISE NOTICE 'CASO 1 (%) ',12;
   
             if(nullvalue(datocateg.cefechafin) 
				  or datocateg.cefechafin::date >= to_timestamp(concat(liq.lianio,'-',liq.limes,'-1') ,'YYYY-MM-DD')::date ) then

                    	--busco la primer categoria de la persona
                    	RAISE NOTICE 'CASO 3 (%)',12;
                      --Dani reemplazo 25062024
                      /*
                       select into datoaux3 * 
				 from ca.categoriaempleado where idcategoriatipo=1 and idpersona= $3  order by cefechainicio  asc limit 1;
                      */ 
                    	select into datoaux3 * 
			from ca.categoriaempleado 
                        where idcategoriatipo=1 
                              and idpersona= $3 
                              and idcategoria<>21 
                        order by cefechainicio  asc limit 1;
                     	if(datoaux3.cefechainicio<=concat(liq.lianio ,'-',1,'-1')::date ) then
                          fechainicionueva=concat(liq.lianio ,'-',1,'-1')::date;
                        	   RAISE NOTICE 'CASO 4 (%)',12;
   
                    	else 
                          fechainicionueva=datoaux3.cefechainicio;
                    	end if;
 
 			SELECT  into cantdias (((date_trunc('month', (concat(liq.lianio ,'-',liq.limes,'-1'))::date ) + interval '1 month') 
                                   - interval '1 day')::date  -  fechainicionueva::date);
       

    	     else  ---por aca 
            		--RAISE NOTICE 'CASO erer1 liq.limes (%) ',liq.limes;
            		if(liq.limes=6)then  ---decia 6
                    		 RAISE NOTICE 'CASO 14 (%)',12;

              -- SELECT  into cantdias (datocateg.cefechafin::date  -   datocateg.cefechainicio::date);
--esto es para el caso de q la persona tiene una categoria menor a primero del mes
   							select into  datoaux1 from ca.categoriaempleado where idpersona =$3 and cefechainicio<=to_timestamp(concat(liq.lianio,'-',1,'-1') ,'YYYY-MM-DD')::date order by  cefechainicio desc limit 1;
     						if found then --la persona tiene categoria con fechainicio menor a 01-01-anioactual
           
             						if(nullvalue(datocateg.cefechafin)) then   
                        					fechafinnueva=concat(liq.lianio ,'-',6,'-30')::date;
             						else
                        					fechafinnueva=datocateg.cefechafin::date;
             						 end if;
                          
       								SELECT  into cantdias (fechafinnueva -  to_timestamp(concat(liq.lianio,'-',1,'-1') ,'YYYY-MM-DD')::date );
             
            						RAISE NOTICE 'CASO dddd (%) ',12;

                 			else -----la persona tiene categoria con fechainicio mayor a 01-01-anioactual
                 					RAISE NOTICE 'MES <>6(%) ',12;
             	 					select into  datoaux2 from ca.categoriaempleado 
				 					where idpersona =$3 and 
              							cefechainicio>=to_timestamp(concat(liq.lianio,'-',1,'-1') ,'YYYY-MM-DD')::date           order by  cefechainicio asc  limit 1;
            
             						if(nullvalue(datocateg.cefechafin)) then   
                        				fechafinnueva=concat(liq.lianio ,'-',6,'-30')::date;
             						else
                        				 fechafinnueva=datocateg.cefechafin::date;
             						end if;
             						SELECT  into cantdias (fechafinnueva::date  - datoaux2.cefechainicio::date);
                      
      						end if; /*found*/
	          ELSE 
			  		SELECT  into cantdias (datocateg.cefechafin	- concat(liq.lianio ,'-',6,'-30')::date);
			        RAISE NOTICE 'ES 12 >>>>>(%) ',cantdias;
    	       end if;/*if(liq.limes=6)then*/
	    RAISE NOTICE 'ACA+ >>>>>(%) ',12;
	
 end if;

end if;
return cantdias;
END;$function$
