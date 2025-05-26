CREATE OR REPLACE FUNCTION public.ingresarpersonaplan(character varying, integer, integer, date, date)
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
fechafinplan date;
 

BEGIN
/*SET search_path = ca, pg_catalog;*/

       elnrodoc = $1;
        eltipodoc = $2;
        elidplan =$3;
        dechainicioplan =$4;
         fechafinplan =$5;
        IF NOT nullvalue(elidplan )THEN
               SELECT INTO personapla * FROM plancobpersona
                    WHERE nrodoc  = elnrodoc and tipodoc = eltipodoc
                          and   idplancoberturas = elidplan;
               IF NOT FOUND THEN -- La persona no esta vinculada al plan
                    INSERT INTO plancobpersona( nrodoc,  tipodoc,  idplancobertura , pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpfechafin)
                    VALUES ( elnrodoc, eltipodoc, elidplan, dechainicioplan, elidplan, dechainicioplan,fechafinplan);
               ELSE
                    IF  (elidplan=6) THEN --06-07-2022 MaLaPi Plan Materno, respeto la fecha de alta de la interface 
                         UPDATE plancobpersona  set pcpfechaalta=dechainicioplan, pcpfechaingreso=dechainicioplan, pcpfechafin=fechafinplan
                         WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas=6;
                    ELSE --06-07-2022 MaLaPi Para los otros se mantiene la fecha historica
                         UPDATE plancobpersona  set pcpfechafin=fechafinplan
                         WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and idplancoberturas=elidplan;
                    END IF;
              END IF;
        END IF;

       /* INCORPORACION AUTOMATICA DE PERSONA A PLAN*/
             -- Se verifica que a la persona le corresponde el plan infantil (7)  
 


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
                               INSERT INTO plancobpersona( nrodoc,  tipodoc,  idplancobertura , pcpfechaalta,  idplancoberturas,     pcpfechaingreso,pcpfechafin)
                               VALUES (elnrodoc, eltipodoc, 13,  now(),  13,  now(),fechafinplan);
                     END IF;
                     UPDATE plancobpersona
                     SET pcpdiagnostico = discapa, pcpprestador =elprest
                     WHERE nrodoc=elnrodoc and tipodoc =eltipodoc and idplancoberturas=13 ;
            END IF;
          /* FIN DISCAPACIDAD*/

 RETURN TRUE;
END;
$function$
