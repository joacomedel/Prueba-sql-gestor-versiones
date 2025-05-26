CREATE OR REPLACE FUNCTION public.actualizarlafechadefinosbenefsosunc(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 tipodocumento alias for $2;
 nrodocumento alias for $1;
aux boolean;
pers RECORD;
recprorroga RECORD;
actadefuncion RECORD;
rdatopadre RECORD;

vencimiento date;
fechafinpadre DATE;
fechacumple DATE;
edad INTEGER;
fechafin DATE;
auxcumple DATE;
cumpleactual DATE;
cumplesig DATE;
vinculo integer;
poseediscapacidadvigente boolean;
elbenefborrado record;

/*Este metodo tiene que ser igual al implementado para el trigger de cambio de estado */
BEGIN
     SELECT INTO pers * FROM persona WHERE nrodoc= nrodocumento and tipodoc=tipodocumento AND ( barra < 30 OR (barra > 100 AND barra < 130));
     IF FOUND THEN
     SELECT INTO rdatopadre persona.fechafinos AS fechafinpadre, benefsosunc.nrodoctitu, benefsosunc.tipodoctitu 
                 FROM persona  JOIN benefsosunc ON benefsosunc.nrodoctitu = persona.nrodoc AND benefsosunc.tipodoctitu = persona.tipodoc
                 WHERE benefsosunc.nrodoc = pers.nrodoc AND benefsosunc.tipodoc = pers.tipodoc;


      -- VAS 02-10-14 si el beneficiario fue borrado se pone como fecha fin la fecha fin en la que fue borrado
      /*Si la persona es un beneficiario y ha sido borrado el estado debe ser pasivo independiente de la fecha calculada*/
      SELECT INTO elbenefborrado * FROM beneficiariosborrados WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc AND nrodoctitu = rdatopadre.nrodoctitu AND tipodoctitu=rdatopadre.tipodoctitu;
  	  IF FOUND THEN
  		         UPDATE persona SET fechafinos = elbenefborrado.borrado WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
  	  ELSE



      SELECT INTO vinculo idvin
                  from benefsosunc
                  where benefsosunc.nrodoc = nrodocumento and benefsosunc.tipodoc=tipodocumento;

      edad = extract(year from age(current_timestamp, pers.fechanac));
      cumplesig = proximocumpleanios(pers.fechanac);


             --raise notice 'Ya seteamos las variables importantes';
--Si posee discapacidad se coloca la fecha de fin del padre.
     select into poseediscapacidadvigente exists(select * from discpersona where discpersona.nrodoc=pers.nrodoc and discpersona.tipodoc=pers.tipodoc and discpersona.fechavtodisc >= current_date);
     if poseediscapacidadvigente then
           UPDATE persona SET fechafinos = rdatopadre.fechafinpadre WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            raise notice 'poseediscapacidadvigente';
     ELSE
      /*09-04-2010 M.L.P Modifico para si tiene un acta de defuncion, le ponga como fecha de fin la fecha del acta de defuncion */
      SELECT INTO actadefuncion * FROM actasdefun WHERE actasdefun.nrodoc = pers.nrodoc  AND actasdefun.tipodoc = pers.tipodoc;
      IF FOUND THEN
      
       UPDATE persona SET fechafinos = actadefuncion.actasdefuncc WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
      ELSE
           if pers.barra > 20 or pers.barra =1 then
                         UPDATE persona SET fechafinos = rdatopadre.fechafinpadre WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
           ELSE /* de pers.barra > 20 */
           IF edad >= 26 THEN /*Hay que darlos de baja */

              UPDATE persona SET fechafinos = date(pers.fechanac) + interval '26 year' WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;

           ELSE /*09-04-2010 M.L.P Hay que ver las prorrogar y demas */
                   IF edad < 17 THEN
                           UPDATE persona SET fechafinos = rdatopadre.fechafinpadre WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                --raise notice 'La fechafinOS es la del padre.';
                   END IF;

                   IF edad = 17 THEN
                                       SELECT INTO recprorroga  *
                                       FROM  prorroga
                                       WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc AND  prorroga.tipoprorr = 18
                                       order by fechavto DESC
                                       limit 1;
                            IF NOT FOUND THEN
                               SELECT INTO fechafin * FROM minimadetresfechas(rdatopadre.fechafinpadre,cumplesig,NULL);
                            ELSE
                                SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,rdatopadre.fechafinpadre,cumplesig);
                            END IF;
                           UPDATE persona SET fechafinos = fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                --raise notice 'La fechafinOS es la menor entre la prorroga, el padre y el cumpleanios.';
                  END IF;
                  
                  IF edad > 17  AND edad < 20 THEN
                                SELECT INTO recprorroga  *
                                       FROM  prorroga
                                       WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc AND  prorroga.tipoprorr = 18
                                       order by fechavto DESC
                                       limit 1;
                    
                                IF NOT FOUND THEN
                                          /*Cuando la PERSONA nace el 29-02 hay que ver que la fecha fin del cumple, tendria que ser en 28-02 */
                                          IF extract(month from to_date(pers.fechanac,'YYYY-MM-DD')) = 2 and extract(day from to_date(pers.fechanac,'YYYY-MM-DD')) = 29 THEN
                                                fechafin = to_date (concat (  extract(year from to_date(pers.fechanac,'YYYY-MM-DD'))+18
                                                           ,'-', extract(month from to_date(pers.fechanac,'YYYY-MM-DD')) ,'-28' ),'YYYY-MM-DD' );
                                          ELSE
                                              fechafin = to_date (concat (  extract(year from to_date(pers.fechanac,'YYYY-MM-DD'))+18
                                              ,'-', extract(month from to_date(pers.fechanac,'YYYY-MM-DD'))  ,'-', extract(day from to_date(pers.fechanac,'YYYY-MM-DD'))),'YYYY-MM-DD'   );
                                          END IF;

                                      UPDATE persona SET fechafinos =fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                                    --raise notice 'La fechafinOS es el cumpleanios 18 no tiene una prorroga ingresada.';
                                 ELSE
                                       SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,rdatopadre.fechafinpadre,NULL);
                                       UPDATE persona SET fechafinos = fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                                       --raise notice 'La fechafinOS es la menor entre la prorroga y el padre.';
                                 END IF; -- IF NOT FOUND THEN
                  
                END IF; -- edad > 17  AND edad < 20

--Dani cambio  el 06-06-18. Por resolucion de consejo la cobertura es solo hasta los 25 inclusive
                IF edad = 20 or edad=25 THEN
                         SELECT INTO recprorroga  *
                                       FROM  prorroga
                                       WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc
                                             AND ( prorroga.tipoprorr = 18 OR prorroga.tipoprorr = 21)
                                       order by fechavto DESC
                                       limit 1;


                         IF NOT FOUND THEN
                                 /*Cuando la PERSONA nace el 29-02 hay que ver que la fecha fin del cumple, tendria que ser en 28-02 */
                                  IF extract(month from to_date(pers.fechanac,'YYYY-MM-DD')) = 2 and extract(day from to_date(pers.fechanac,'YYYY-MM-DD')) = 29 THEN
                                          fechafin = to_date ( concat (extract(year from to_date(pers.fechanac,'YYYY-MM-DD'))+18  ,'-', extract(month from to_date(pers.fechanac,'YYYY-MM-DD'))  ,'-28'),'YYYY-MM-DD' );
                                  ELSE
                                          fechafin = to_date (concat (extract(year from to_date(pers.fechanac,'YYYY-MM-DD'))+18  ,'-', extract(month from to_date(pers.fechanac,'YYYY-MM-DD'))  ,'-', extract(day from to_date(pers.fechanac,'YYYY-MM-DD'))),'YYYY-MM-DD' );
                                   END IF;

                                   UPDATE persona SET fechafinos = to_date(fechafin,'YYYY-MM-DD') WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                                   raise notice 'La fechafinOS es el cumpleanios 18 no tiene una prorroga ni de 18 ni de 21';
                         else
                                   SELECT INTO fechafin * FROM minimadetresfechas(to_date(recprorroga.fechavto,'YYYY-MM-DD'),to_date(rdatopadre.fechafinpadre,'YYYY-MM-DD'),to_date(cumplesig,'YYYY-MM-DD'));
                                   UPDATE persona SET fechafinos =to_date(fechafin,'YYYY-MM-DD') WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                                   raise notice 'La fechafinOS es la menor entre la prorroga de 18 o 21 y el padre y su siguiente cumple (%)(%)(%)(ffos %)',recprorroga.fechavto,rdatopadre.fechafinpadre,cumplesig,to_date(fechafin,'YYYY-MM-DD');
                         end if; 
                  END IF; --edad = 20 or edad=25


               IF edad > 20  AND edad < 25 THEN
                              -- MaLaPi 05/10/2009 Saco la posibilidad de que si la persona tiene mas de 21 años, tome
                              -- como valido una prorroga de 21 años.

                                 SELECT INTO recprorroga  *
                                       FROM  prorroga
                                       WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc
                                             AND prorroga.tipoprorr = 21
                                       order by idprorr DESC
                                       limit 1;
                  
                              IF NOT FOUND THEN
                                     /*Cuando la PERSONA nace el 29-02 hay que ver que la fecha fin del cumple, tendria que ser en 28-02 */
                                     IF extract(month from to_date(pers.fechanac,'YYYY-MM-DD')) = 2 and extract(day from to_date(pers.fechanac,'YYYY-MM-DD')) = 29 THEN
                                                      SELECT INTO fechafin * FROM maximadetresfechas(pers.fechainios,to_date( concat (  extract(year from to_date(pers.fechanac,'YYYY-MM-DD'))+21  ,'-', extract(month from to_date(pers.fechanac,'YYYY-MM-DD')) ,'-28')),'YYYY-MM-DD',NULL);
                                                   
                                      ELSE
                                                      SELECT INTO fechafin * FROM maximadetresfechas(pers.fechainios,to_date(concat ( extract(year from to_date(pers.fechanac,'YYYY-MM-DD'))+21 ,'-', extract(month from to_date(pers.fechanac,'YYYY-MM-DD')) ,'-', extract(day from to_date(pers.fechanac,'YYYY-MM-DD'))),'YYYY-MM-DD'),NULL);
                                          
                                      END IF;


                                      UPDATE persona SET fechafinos =  to_date(fechafin,'YYYY-MM-DD') WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                                      raise notice 'La fechafinOS es el cumpleanios 18 no tiene una prorroga ingresada ni de 18 ni de 21.';
                               ELSE
                                      SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,rdatopadre.fechafinpadre,NULL);
                                      UPDATE persona SET fechafinos = to_date( fechafin,'YYYY-MM-DD') WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                                      raise notice 'La fechafinOS es la menor entre la prorroga de 21 o 18 y el padre.';
                               END IF;
                END IF;
           END IF;
             END IF;


end if;
end if;
END IF;
END IF; -- IF FOUND de pers 
return 'TRUE';

END;
$function$
