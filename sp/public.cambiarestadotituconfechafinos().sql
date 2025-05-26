CREATE OR REPLACE FUNCTION public.cambiarestadotituconfechafinos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$/*Verifica que el estado se corresponda con el que deberia tener segun su fechafinos, en caso de no se
un esdo valido, se actualiza al estado valido
*/
DECLARE

    per RECORD;
    fechafin DATE;
    fechafinactivo DATE;
    pertitular RECORD;
    rcontrato RECORD;
   
    aux record;
BEGIN
       -- RAISE NOTICE 'Hola aca estoy......';
        SELECT INTO per * FROM persona WHERE nrodoc = NEW.nrodoc AND tipodoc = NEW.tipodoc;
        SELECT INTO fechafinactivo  per.fechafinos::date  - 90;
  	fechafin = per.fechafinos;
  		
	--raise notice 'fechafin (%) ', fechafin;
  	
	if(fechafin < current_date) /*Corresponde asignarle estado pasivo*/
  	then
              RAISE NOTICE 'Hola aca estoy 2<(%)>......',per.barra;
  	       if(per.barra < 30) then /*Se trata de un benefsosunc*/
                     UPDATE benefsosunc SET idestado = 4 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
  	       else /*Se trata de un afilsosunc*/
                     -- RAISE NOTICE 'Hola aca estoy 3......';
  		        if(per.barra >= 30 and per.barra <= 37) then
  		                      UPDATE afilsosunc SET idestado = 4 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                        else
                              -- RAISE NOTICE 'Hola aca estoy 3......';
                             if(per.barra >= 100) then
 --RAISE NOTICE 'Hola aca estoy 4......';
                                  UPDATE afilreci SET idestado = 4 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                                  UPDATE benefreci SET idestado = 4 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;  
                             end if;
                        end if;
  		       
  	        end if;
  	else /*La persona aun se encuentra con cebertura de la Obra Social*/
  		   if(fechafinactivo < current_date) /* Ya se le termino la designacion o resolucion, corresponde estado Compensacion de Carencia*/
  				then
       raise notice 'ENTRO AL SI cambiarestadotituconfechafinos  (%) ',per.barra;
     			             if(per.barra < 30) then /*Se trata de un benefsosunc*/
                                         --RAISE NOTICE 'Hola barra < 30......';
   			                  SELECT INTO pertitular * FROM persona
                                          JOIN benefsosunc ON (persona.nrodoc = benefsosunc.nrodoctitu
   			                                  AND persona.tipodoc = benefsosunc.tipodoctitu)
                                           WHERE benefsosunc.nrodoc= per.nrodoc AND benefsosunc.tipodoc = per.tipodoc;
                                          IF  (pertitular.barra = 34 OR pertitular.barra = 35 OR pertitular.barra = 36) THEN
                                                 UPDATE benefsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                                                 raise notice 'barra 35 ' ; 
                                          ELSE
                                               --RAISE NOTICE 'Hola No es el otro......';
                                               UPDATE benefsosunc SET idestado = 3 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                                          END IF;
                                else /*Se trata de un afilsosunc*/
                                      IF (per.barra = 34 OR per.barra = 35 OR per.barra = 36 ) THEN
                                              UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                                      ELSE

                                            SELECT INTO rcontrato * 
                                            FROM ca.persona NATURAL JOIN ca.empleado NATURAL JOIN ca.empleadocontratotipo
                                            WHERE NULLVALUE(ecfechafin) AND idcontratotipo = 5  AND per.barra = 32;
                                            IF FOUND THEN 
/*KR 29-01-20 SI es un contratado entonces esta activo. */
                                                      UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                                             ELSE
                                                     UPDATE afilsosunc SET idestado = 3 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                                             END IF;
                                     END IF;

                               end if;
  		    else
                        /*Aun tiene designacion vigente o resolucion vigente, no se tiene en cuenta el estado Carencia de Servicios */
		         /*Corresponde Activo para el Titular y sus Beneficiarios*/
                        if(per.barra < 30) then /*Se trata de un benefsosunc*/
                             UPDATE benefsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                        end if;
                         if(per.barra >= 30 and per.barra <= 37) then /*Se trata de un afilsosunc*/
                             UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                        end if;	
                        if(per.barra > 100 and per.barra <130) then
                                  UPDATE benefreci SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                         end if;
                        if(per.barra >= 130) then
                                  UPDATE afilreci SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                         end if;
                       end if;
      end if;
      /*MALAPI*/
SELECT INTO aux * FROM actualizarctacte(NEW.nrodoc,NEW.tipodoc);
  return NEW;
end;
$function$
