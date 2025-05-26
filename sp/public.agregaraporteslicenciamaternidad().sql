CREATE OR REPLACE FUNCTION public.agregaraporteslicenciamaternidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
--RECORD 
	rverifica RECORD;
        rdatocargo RECORD;
	rlicencias RECORD;
        rliquidacion RECORD;
        rcargo RECORD;
        raporte RECORD;
        rcuentac RECORD;
        rconcepto RECORD;
        rcargom RECORD;

--CURSOR
        clicencias refcursor; 
        elidcargo INTEGER; 

BEGIN
  SELECT INTO rcuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
  SELECT INTO rliquidacion * FROM liquidacion WHERE mes = date_part('month', current_date -30)
                                                  AND  	anio= date_part('year', current_date - 30)
                                                  LIMIT 1;
 
   
 
 --Busca todas las licencias activas    
 OPEN clicencias FOR SELECT * 
                     FROM licencias
                     WHERE  fechaini<CURRENT_DATE AND fechafin>=CURRENT_DATE;


 FETCH clicencias INTO rverifica;
    
 
     
   WHILE  found LOOP
    elidcargo = rverifica.idcargo;

      IF nullvalue(elidcargo) THEN
          SELECT INTO rcargom max(fechafinlab) as fechafinlab, max(idcargo) as idcargo, legajosiu 
          FROM cargo WHERE  legajosiu = rverifica.legajosiu GROUP BY legajosiu;
         IF  FOUND THEN
          UPDATE cargo SET fechafinlab=rverifica.fechafin WHERE idcargo = rcargom.idcargo;
          elidcargo = rcargom.idcargo;
          END IF;  
      else
            UPDATE cargo SET fechafinlab=rverifica.fechafin WHERE idcargo = elidcargo;
            
      END IF;  
   

IF not nullvalue(elidcargo) THEN

     SELECT INTO raporte * FROM aporte WHERE idcargo = elidcargo
                                        AND nroliquidacion = rliquidacion.nroliquidacion
                                        AND ano =  date_part('year', current_date - 30)
                                        AND mes =  date_part('month', current_date -30);
    IF NOT FOUND THEN
      
          INSERT INTO aporte  (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
           VALUES (date_part('year', current_date -30),true,current_date,elidcargo,null,elidcargo,rverifica.idlicencias,null,null,rliquidacion.idtipoliq,0,date_part('month', current_date -30),rliquidacion.nroliquidacion,rcuentac.nrocuentac);

    ELSE
               UPDATE aporte SET importe = importe + 0
                      WHERE idcargo = elidcargo
                       AND nroliquidacion = rliquidacion.nroliquidacion
                       AND ano = date_part('year', current_date -30)
                       AND mes =date_part('month', current_date -30);
      END IF;

    
   
END IF;
    

FETCH clicencias INTO rverifica;
END LOOP;
CLOSE clicencias;

return true;

END;
$function$
