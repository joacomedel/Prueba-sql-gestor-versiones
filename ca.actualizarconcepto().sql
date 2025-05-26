CREATE OR REPLACE FUNCTION ca.actualizarconcepto()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
      
    unconcepto RECORD;
    lacategoria integer;
    rsliquidacion RECORD;
    datoaux RECORD;


    cursorconcepto  CURSOR FOR  SELECT *   FROM tempconcepto;


BEGIN
SET search_path = ca, pg_catalog;
lacategoria=null;



 --SELECT INTO rsliquidacion * FROM ca.liquidacion WHERE nullvalue(lifechapago);
   

 OPEN cursorconcepto ;

FETCH cursorconcepto into unconcepto;
      WHILE  found LOOP
     UPDATE ca.concepto SET  codescripcion =unconcepto.codescripcion
					,comonto =unconcepto.comonto
					,coporcentaje=unconcepto.coporcentaje
					,idconceptotipo=unconcepto.idconceptotipo
					,activo =unconcepto.activo
				        ,cimprime =unconcepto.cimprime
				        ,coautomatico =unconcepto.coautomatico
					,coimprimeporcentaje =unconcepto.coimprimeporcentaje
					 WHERE idconcepto =unconcepto.idconcepto;
	 
	if (not nullvalue(unconcepto.idconceptotope))then
		UPDATE ca.conceptotope SET   ctfechahasta=now() WHERE idconceptotope = unconcepto.idconceptotope;
				 
	 
	     if((unconcepto.idcategoria)!=0 AND (not nullvalue(unconcepto.idcategoria)) ) then

 	         lacategoria=unconcepto.idcategoria;

             end if; 

            INSERT into ca.conceptotope (ctmontominimo,ctmontomaximo,idconcepto,ctfechadesde,idcategoria) 
            VALUES   (unconcepto.ctmontominimo,unconcepto.ctmontomaximo,unconcepto.idconcepto,now(),lacategoria);
                   
	end if;  
        

   

--actualizo todos los empleados que tienen ese concepto en las liquidaciones abiertas
   
if(unconcepto.aplicatodosempleados) then 
  
    update ca.conceptoempleado set ceporcentaje=unconcepto.coporcentaje
    where  conceptoempleado.idconcepto=unconcepto.idconcepto 
            and (conceptoempleado.idliquidacion) in
           (select idliquidacion from ca.liquidacion WHERE nullvalue(lifechapago));

     
end if;
    
 FETCH cursorconcepto into unconcepto;
 END LOOP;
CLOSE cursorconcepto;

return true;
END;$function$
