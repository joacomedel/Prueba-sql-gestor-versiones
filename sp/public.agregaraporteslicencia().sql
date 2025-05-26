CREATE OR REPLACE FUNCTION public.agregaraporteslicencia()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
--RECORD 
	rverifica RECORD;
	rlicencias RECORD;
        rliquidacion RECORD;
        rcargo RECORD;
        raporte RECORD;
        rcuentac RECORD;
        rconcepto RECORD;
        rcargom RECORD;
        rcargoaux RECORD;
        rultimocargo RECORD;
        
        ultimafechaingreso date;

--CURSOR
        clicencias refcursor; 
        

--VARIABLES
        elidcargo INTEGER; 

BEGIN
   SELECT INTO rcuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
   SELECT INTO rliquidacion * FROM dh21 WHERE mesingreso = case when date_part('day', current_date -30) > 15 then date_part('month', current_date) else date_part('month', current_date -30) end AND anioingreso= case when date_part('day', current_date -30) > 15 then date_part('year', current_date) else date_part('year', current_date -30)  end  LIMIT 1;


/*Dani agrego el 10082022 para dar de baja todas las licencias activas que  ya no vienen informadas  tanto de la tabla licencias como de licsinhab*/
/*busco la ultima fecha de ingreso de licencias par aluego dar de baja las que no vinieron informadas en el archivo de LSGH*/
SELECT into ultimafechaingreso fechaingreso 
                     FROM licencias
                     order by fechaingreso desc limit 1;



 update licencias set fechafin=current_date-1 where (idlicencias,idcentrolicencias) in
(SELECT idlicencias,idcentrolicencias
                     FROM licencias
                      WHERE  fechaingreso <ultimafechaingreso   and  fechafin>=CURRENT_DATE);

  

update licsinhab set fechafinlic=current_date-1 where (idlic) in
(SELECT idlic
                     FROM licsinhab join licencias using(idcargo)
                      WHERE  licencias.fechafin <=CURRENT_DATE   and  licsinhab.fechafinlic>=CURRENT_DATE);

  
 


           
 OPEN clicencias FOR SELECT * 
                     FROM licencias
                     WHERE  fechaini<CURRENT_DATE AND fechafin>=CURRENT_DATE;
                  

 FETCH clicencias INTO rverifica;
 WHILE  found LOOP
    
    --KR 01-02-17 para el caso de las LM como el cargo no viene y no esta quizas en el dh49 busco el ultimo que tuvo y si no esta vigente le pongo como fecha fin la fecha que viene en el archivo
      elidcargo = rverifica.idcargo;
      IF nullvalue(elidcargo) THEN
          SELECT INTO rcargom max(fechafinlab) as fechafinlab, max(idcargo) as idcargo, legajosiu 
          FROM cargo WHERE  legajosiu = rverifica.legajosiu GROUP BY legajosiu;

          UPDATE cargo SET fechafinlab=rverifica.fechafin WHERE idcargo = rcargom.idcargo;
          elidcargo = rcargom.idcargo;
       else /*si el cargo no es nulo veo si esta asignado o no a esa persona*/
          SELECT INTO rcargoaux *
          FROM cargo WHERE  legajosiu = rverifica.legajosiu 
                    and idcargo = rverifica.idcargo GROUP BY legajosiu,idcargo;
          IF FOUND THEN
                   UPDATE cargo SET fechafinlab=rverifica.fechafin WHERE idcargo = elidcargo;
          ELSE 
              SELECT INTO rultimocargo max(fechafinlab) as fechafinlab, max(idcargo) as idcargo, legajosiu 
              FROM cargo WHERE  legajosiu = rverifica.legajosiu GROUP BY legajosiu;

              UPDATE cargo SET fechafinlab=rverifica.fechafin WHERE idcargo = rultimocargo.idcargo;
              elidcargo = rultimocargo.idcargo;

          END IF;
           
            
      END IF;

     SELECT INTO rcargo     -- Busca el cargo del afiliado 
          public.cargo.idcargo,
          public.cargo.fechainilab,
          public.cargo.fechafinlab,
          public.cargo.tipodoc,
          public.cargo.nrodoc
     FROM public.cargo      
     WHERE  legajosiu = rverifica.legajosiu  and 
            idcargo= elidcargo;
       
 IF  FOUND THEN

     SELECT INTO raporte * FROM aporte WHERE idcargo = rcargo.idcargo
                                        AND nroliquidacion = rliquidacion.nroliquidacion
                                        AND ano =  date_part('year', current_date - 30)
                                        AND mes =  date_part('month', current_date -30);
    IF NOT FOUND THEN
      
          INSERT INTO aporte  (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
           VALUES (date_part('year', current_date -30),true,current_date,rcargo.idcargo,null,elidcargo,rverifica.idlicencias,null,null,rliquidacion.nroliquidacion,0,date_part('month', current_date -30),rliquidacion.nroliquidacion,rcuentac.nrocuentac);


INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de licencia',1,now(),centro());
               INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de la licencia',7,null,centro()); 
 

      ELSE
               UPDATE aporte SET importe = importe + 0
                      WHERE idcargo = rcargo.idcargo
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
