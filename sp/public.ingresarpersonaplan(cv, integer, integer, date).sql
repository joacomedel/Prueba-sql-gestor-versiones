CREATE OR REPLACE FUNCTION public.ingresarpersonaplan(character varying, integer, integer, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que ingresa o modifica la informacion de personas vinculadas a un plan de cobertura*/
DECLARE

 elplanpers refcursor;

 personapla RECORD;
 datospersona RECORD;
 datosdiscapacidad refcursor;
 ladiscapacidad RECORD;
 elprest VARCHAR;
 discapa VARCHAR;
 elnrodoc VARCHAR;
 eltipodoc INTEGER;
 elidplan INTEGER;
 dia INTEGER;
 dechainicioplan date;

fechaingresoplan date;
 

BEGIN
/*SET search_path = ca, pg_catalog;*/

       elnrodoc = $1;
        eltipodoc = $2;
        elidplan =$3;
        dechainicioplan =$4;
        IF NOT nullvalue(elidplan )THEN
               SELECT INTO personapla * FROM plancobpersona
                    WHERE nrodoc  = elnrodoc and tipodoc = eltipodoc
                          and   idplancoberturas = elidplan;
               IF NOT FOUND THEN -- La persona no esta vinculada al plan
                    INSERT INTO plancobpersona( nrodoc,  tipodoc,  idplancobertura , pcpfechaalta,  idplancoberturas,     pcpfechaingreso)
                    VALUES ( elnrodoc, eltipodoc, elidplan, dechainicioplan, elidplan, dechainicioplan);
               ELSE
                    IF  (elidplan=6) THEN
                         UPDATE plancobpersona  set pcpfechaalta=dechainicioplan, pcpfechaingreso=dechainicioplan ,pcpfechafin=null
                         WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =6;

                    END IF;
              END IF;
        END IF;

       /* INCORPORACION AUTOMATICA DE PERSONA A PLAN*/
             -- Se verifica que a la persona le corresponde el plan infantil (7)  
 
       dia=EXTRACT(DAY FROM NOW());


        SELECT  INTO datospersona *
/*extract(YEAR from age(fechanac)) as edad, to_DATE(concat(EXTRACT(YEAR FROM fechanac) ,'-',EXTRACT(MONTH FROM fechanac),'-1'),'YYYY-MM-DD') as fechaingresoplan*/
        FROM persona
        WHERE nrodoc=elnrodoc and tipodoc= eltipodoc;

      if  (dia <16) then

       fechaingresoplan=  to_DATE(concat(EXTRACT(YEAR FROM to_date(datospersona.fechanac,'YYYY-MM-DD')) ,'-',EXTRACT(MONTH FROM to_date(datospersona.fechanac,'YYYY-MM-DD')),'-1'),'YYYY-MM-DD');

     else

       fechaingresoplan=  to_DATE(concat(EXTRACT(YEAR FROM to_date(datospersona.fechanac,'YYYY-MM-DD')) ,'-',(EXTRACT(MONTH FROM to_date(datospersona.fechanac,'YYYY-MM-DD')) ),'-1'),'YYYY-MM-DD')+'1 month'::interval;
         
      end if;

        /*verifica la edad*/
        IF (extract(YEAR from age(datospersona.fechanac)) <= 1) THEN
                      SELECT INTO personapla * FROM plancobpersona
                       WHERE nrodoc  = elnrodoc and tipodoc = eltipodoc
                              and   idplancoberturas = 7 ;
                       IF NOT FOUND THEN -- La persona no esta vinculada al plan
                          INSERT INTO plancobpersona
                                  ( nrodoc,  tipodoc,  idplancobertura , pcpdiagnostico,   pcpfechaalta,  idplancoberturas,     pcpfechaingreso)
                          VALUES (elnrodoc, eltipodoc, 7,'Plan Infantil',fechaingresoplan,  7,  fechaingresoplan);
                       END IF;
             END IF;
             /* FIN INFANTIL*/

/*INICIO PLAN ODONTOINFANTIL*/
    IF (extract(YEAR from age(datospersona.fechanac)) <= 15) THEN
                      SELECT INTO personapla * FROM plancobpersona
                       WHERE nrodoc  = elnrodoc and tipodoc = eltipodoc
                              and   idplancoberturas = 24 ;
                       IF NOT FOUND THEN -- La persona no esta vinculada al plan
        
                          INSERT INTO plancobpersona
                                  ( nrodoc,  tipodoc,  idplancobertura , pcpdiagnostico,   pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpfechafin)
                          VALUES (elnrodoc, eltipodoc, 24,'PLAN PREVENTIVO ODONTOPEDIATRICO',fechaingresoplan,  24,fechaingresoplan, (datospersona.fechanac+interval '15 years')::date);
                       END IF;
             END IF;
 /* FIN  PLAN PREVENTIVO ODONTOPEDIATRICO*/


             /* INICIO DISCAPACIDAD*/
     
           OPEN datosdiscapacidad FOR  SELECT *  FROM  discpersona NATURAL JOIN discapacidad   WHERE nrodoc=elnrodoc and tipodoc= eltipodoc;
           FETCH datosdiscapacidad INTO ladiscapacidad;
           WHILE FOUND LOOP
                  discapa = '';
                  elprest  = '';
                  discapa = concat(ladiscapacidad.descrip,'// ',discapa);
                  elprest = concat(ladiscapacidad.entemitecert,'// ',elprest);
                  FETCH datosdiscapacidad into ladiscapacidad;
            END LOOP;
            CLOSE datosdiscapacidad;
            IF discapa <> '' THEN
                           -- Se verifica que a la persona le corresponde el Discapacidad (13)
                     SELECT INTO personapla *
                     FROM plancobpersona
                     WHERE nrodoc=elnrodoc and tipodoc= eltipodoc
                           and idplancoberturas = 13 ;
                     IF  NOT FOUND THEN
                               INSERT INTO plancobpersona( nrodoc,  tipodoc,  idplancobertura , pcpfechaalta,  idplancoberturas,     pcpfechaingreso)
                               VALUES (elnrodoc, eltipodoc, 13,  now(),  13,  now());
                     END IF;
                     UPDATE plancobpersona
                     SET pcpdiagnostico = discapa, pcpprestador =elprest
                     WHERE nrodoc=elnrodoc and tipodoc =eltipodoc and idplancoberturas=13 ;
            END IF;
          /* FIN DISCAPACIDAD*/

 RETURN TRUE;
END;
$function$
