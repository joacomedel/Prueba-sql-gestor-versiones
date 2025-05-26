CREATE OR REPLACE FUNCTION ca.actualizarconcepto(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
       cursorconcepto refcursor;
       unconcepto RECORD;
       lacategoria varchar;
 
BEGIN
SET search_path = ca, pg_catalog;
lacategoria=null;

 OPEN cursorconcepto FOR SELECT *
                                FROM tempconcepto;

FETCH cursorconcepto into unconcepto;
      WHILE  found LOOP
     UPDATE concepto SET  codescripcion =tempconcepto.codescripcion
					,comonto =tempconcepto.comonto
					,coporcentaje=tempconcepto.coporcentaje
					,idconceptotipo=tempconcepto.idconceptotipo
					,activo =tempconcepto.activo
				        ,cimprime =tempconcepto.cimprime
				        ,coautomatico =tempconcepto.coautomatico
					,coimprimeporcentaje =tempconcepto.coimprimeporcentaje
					 WHERE idconcepto =tempconcepto.idconcepto;
	 
	if (not nullvalue(unconcepto.idconceptotope))then
		UPDATE ca.conceptotope SET   ctfechahasta=now() WHERE idconceptotope = unconcepto.idconceptotope;
				 
	            
	end if;   

  
        
	if((unconcepto.idcategoria)!=0 && not nullvalue(unconcepto.idcategoria)) then
	    	   lacategoria=unconcepto.idcategoria;
          INSERT into ca.conceptotope (ctmontominimo,ctmontomaximo,idconcepto,ctfechadesde,idcategoria) 
          VALUES   (unconcepto.ctmontominimo,unconcepto.ctmontomaximo,unconcepto.idconcepto,now(),lacategoria);

         end if; 

    FETCH cursorconcepto into unconcepto;
   END LOOP;
CLOSE cursorconcepto;
END;
$function$
