CREATE OR REPLACE FUNCTION public.ingresarpersonaplan(character varying, integer, integer, character varying, date, date, character varying, character varying)
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
 eldiagnostico VARCHAR;
 dia INTEGER;
 dechainicioplan date;
 dechafinplan date;
 detalleinforme VARCHAR;
 resumeninforme VARCHAR;

--este atributo va a guardar el valor del diagnostico de una tupla ANTES de haberle agregado el nuevo diagnostico
diagnosticoActual VARCHAR;

fechaingresoplan date;
 

BEGIN
/*SET search_path = ca, pg_catalog;*/
       elnrodoc = $1;
        eltipodoc = $2;
        elidplan =$3;
		eldiagnostico = $4;
        dechainicioplan =$5;
		dechafinplan=$6;
		detalleinforme = $7;
		resumeninforme = $8;
        IF NOT nullvalue(elidplan )THEN
               SELECT INTO personapla * FROM plancobpersona
                    WHERE nrodoc  = elnrodoc and tipodoc = eltipodoc
                          and   idplancoberturas = elidplan;
               IF NOT FOUND THEN -- La persona no esta vinculada al plan
                    INSERT INTO plancobpersona( nrodoc,  tipodoc,  idplancobertura , pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpfechafin,pcpdetalleinforme, pcppresinforme)
                    VALUES ( elnrodoc, eltipodoc, elidplan, dechainicioplan, elidplan, dechainicioplan,dechafinplan,detalleinforme,resumeninforme);
               ELSE
			   		UPDATE plancobpersona set pcpdetalleinforme = detalleinforme, pcppresinforme = resumeninforme,pcpfechafin=dechafinplan
                    WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =elidplan;      
					IF  (elidplan=6) THEN
                         UPDATE plancobpersona  set pcpfechaalta=dechainicioplan, pcpfechaingreso=dechainicioplan ,pcpfechafin=dechafinplan
                         WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =6;

                    END IF;
              END IF;
			  -- Si es plan oncologico, seteamos el diagnostico elegido
			  IF (elidplan = 2) THEN	  		
					diagnosticoActual = (
						SELECT pcpdiagnostico
						FROM plancobpersona
						WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =elidplan
					);
					-- Si el diagnostico a cargar ya esta cargado, no hace falta agregarlo otra vez
					RAISE NOTICE 'd %', (diagnosticoActual);
					IF diagnosticoActual IS NULL OR (POSITION(eldiagnostico IN diagnosticoActual)<=0) THEN
						RAISE NOTICE 'e';
						-- Si el diagnostico a cargar es el primero que sera cargado, no concatenamos en caracter ','
						IF (diagnosticoActual IS NOT NULL AND diagnosticoActual != '') THEN
							eldiagnostico = CONCAT(',',eldiagnostico);
						END IF;
					
			  			UPDATE plancobpersona set pcpdiagnostico = CONCAT(diagnosticoActual,eldiagnostico)
						WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =elidplan;
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
                                  ( nrodoc,  tipodoc,  idplancobertura , pcpdiagnostico,   pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpdetalleinforme, pcppresinforme)
                          VALUES (elnrodoc, eltipodoc, 7,'Plan Infantil',fechaingresoplan,  7,  fechaingresoplan,detalleinforme,resumeninforme);
                       ELSE
					   		UPDATE plancobpersona set pcpdetalleinforme = detalleinforme, pcppresinforme = resumeninforme
                    		WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =7;    
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
                                  ( nrodoc,  tipodoc,  idplancobertura , pcpdiagnostico,   pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpfechafin,pcpdetalleinforme, pcppresinforme)
                          VALUES (elnrodoc, eltipodoc, 24,'PLAN PREVENTIVO ODONTOPEDIATRICO',fechaingresoplan,  24,fechaingresoplan, (datospersona.fechanac+interval '15 years')::date,
								 detalleinforme,resumeninforme);
                       ELSE
					   		UPDATE plancobpersona set pcpdetalleinforme = detalleinforme, pcppresinforme = resumeninforme
                    		WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas =24;    
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
                               INSERT INTO plancobpersona( nrodoc,  tipodoc,  idplancobertura , pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpdetalleinforme, pcppresinforme)
                               VALUES (elnrodoc, eltipodoc, 13,  now(),  13,  now(),detalleinforme,resumeninforme);
                     END IF;
                     UPDATE plancobpersona
                     SET pcpdiagnostico = discapa, pcpprestador =elprest, pcpdetalleinforme= detalleinforme, pcppresinforme = resumeninforme
                     WHERE nrodoc=elnrodoc and tipodoc =eltipodoc and idplancoberturas=13 ;
            END IF;
          /* FIN DISCAPACIDAD*/
 RETURN TRUE;
END;

$function$
