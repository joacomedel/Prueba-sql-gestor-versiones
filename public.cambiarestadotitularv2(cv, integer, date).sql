CREATE OR REPLACE FUNCTION public.cambiarestadotitularv2(character varying, integer, date)
 RETURNS date
 LANGUAGE plpgsql
AS $function$/* Recibe como parametros el tipo y numero de documento y una fecha para la que se necesita
* determinar el estado.
* Retorna, un boolean que determina si hay o no error
*
* Se determina el estado en el que tiene que estar un titular, segun los datos
* de designacion vigente y sus aportes.
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       pfechaactual alias for $3;
       cont integer;
       rpersona RECORD;
       aportePersona RECORD;

       caru3meses integer;
       nroinforme bigint;
       stipoinforme VARCHAR;
       fechaultimoaporte DATE;
       fechafinobrasoc DATE;
       
       rdesVigente RECORD;
       datosCargo RECORD;
       datosbecarios RECORD;
       raportejubpen RECORD;
       actadefuncion RECORD;
       mescondesignacionvigente INTEGER;
       cantaportesult3meses INTEGER;
       resultado2 boolean;
       fechaIniCargo date;
       fechaSalida date;
       reclicsinhab RECORD;
       tienelic boolean;
     cargoact record;
       unatupla record; 
       rlicencia record; 
--cursor 
   ccargolic refcursor;
begin
-- tipodoc   nrodoc fechafinos                    estado ultimoaporte fechafinmaximocargo legajosiu
 --     1 23714539 29/11/2009 COMPENSACIÓN DE SERVICIOS   31/10/2009          31/01/2010        94
--pfechaactual = CURRENT_DATE;
/*El nroTipoInforme es el anio*100 + mes*/
    SELECT INTO rpersona * FROM persona WHERE nrodoc = pnrodoc AND tipodoc = ptipodoc;
/*09-04-2010 M.L.P Se modifica para que verifique si se tiene un acta de defuncion, en ese caso, la fecha de finos es
la fecha de presentacion del acta de defuncion + 90 dias*/
 SELECT INTO actadefuncion * FROM actasdefun WHERE actasdefun.nrodoc = rpersona.nrodoc  AND actasdefun.tipodoc = rpersona.tipodoc;
      IF FOUND THEN
               if(nullvalue( actadefuncion.adffechafallecio) )THEN
                              fechaSalida = actadefuncion.actasdefuncc + '3 month'::interval;
               ELSE
                              fechaSalida =actadefuncion.adffechafallecio;
               END IF;
      ELSE


    nroinforme = cast(date_part('year', pfechaactual) as integer) * 100 + cast(date_part('month', pfechaactual) as integer);



    SELECT INTO fechaultimoaporte * FROM ultimoaporterecibido(pnrodoc,ptipodoc);
    SELECT INTO rdesVigente * FROM cargo WHERE nrodoc = pnrodoc and tipodoc =  ptipodoc and fechafinlab >= pfechaactual;
    /* Buscar una Designacion Vigente para la persona */
   IF (FOUND AND rpersona.barra<>35 AND rpersona.barra<>36 AND rpersona.barra<>37) OR  (rpersona.barra =34)  THEN
   --Existe una designacion Vigente
           tienelic =false;
             IF rpersona.barra = 34 THEN
                  SELECT INTO datosbecarios  max(fechafinlab) as finMasNuevo, min(fechainilab)as iniMasAntiguo
                  FROM afilibec NATURAL JOIN resolbec WHERE nrodoc=pnrodoc and tipodoc=ptipodoc AND fechafinlab>= pfechaactual;
                  IF nullvalue(datosbecarios.finMasNuevo)  THEN
                     SELECT INTO datosbecarios  max(fechafinlab) as finMasNuevo, min(fechainilab)as iniMasAntiguo
                     FROM afilibec NATURAL JOIN resolbec WHERE nrodoc=pnrodoc and tipodoc=ptipodoc ;
                  END IF;
             ELSE
                 SELECT INTO datosCargo  max(fechafinlab) as finMasNuevo, min(fechainilab)as iniMasAntiguo
                 FROM cargo
                 WHERE cargo.nrodoc = pnrodoc AND cargo.tipodoc = ptipodoc AND fechafinlab>= pfechaactual;
           
                 /* Se busca una licencia sin goze de haberes para ese cargo*/
                 SELECT into cargoact *
                 FROM licsinhab NATURAL JOIN cargo
                 WHERE cargo.nrodoc = pnrodoc AND cargo.tipodoc = ptipodoc AND fechafinlab>= pfechaactual
                       and now()<=fechafinlic AND  now()>= fechainilic ;
                 IF FOUND THEN
                    tienelic =true;
                    /*fechaultimoaporte =concat(date_part('month',fechaultimoaporte),'/10/', date_part('year',fechaultimoaporte));*/
fechaultimoaporte =concat('10/',date_part('month',fechaultimoaporte),'/',  date_part('year',fechaultimoaporte));
                 ELSE 
     --KR 22-10-18 puede ser que tenga licencia pq viene el dh de licencias pero no haya realizado el tramite de afilación, busco en tabla licencias 
/*KR 20-08-20 HAY afiliados que tienen mas de un cargo y tienen licencia sobre solo alguno de ellos, no todos, pero como estaba formulada la consulta si encuentra uno con licencia asume que el afiliado tiene licencia en todos los cargos. Ejemplo afiliado '16180203' no tiene licencia del cargo 104511 si de los otros 2 
                    SELECT  into cargoact *           
                    FROM cargo JOIN licencias USING(legajosiu,idcargo) 	
                    WHERE cargo.nrodoc=pnrodoc AND cargo.tipodoc=ptipodoc AND fechafinlab>= pfechaactual and now()<=fechafin AND  now()>= fechaini;
*/
                    SELECT INTO cont COUNT(*) FROM cargo WHERE cargo.nrodoc = pnrodoc AND cargo.tipodoc = ptipodoc AND fechafinlab>= pfechaactual;
                    OPEN ccargolic FOR SELECT * FROM cargo WHERE cargo.nrodoc = pnrodoc AND cargo.tipodoc = ptipodoc AND fechafinlab>= pfechaactual;
                    FETCH ccargolic INTO unatupla;
                    WHILE FOUND LOOP                            
                             SELECT INTO rlicencia * FROM licencias WHERE legajosiu=unatupla.legajosiu AND idcargo=unatupla.idcargo and now()<=fechafin AND now()>= fechaini;
                             if found then 
                                cont = cont-1;
                             end if;
                   FETCH ccargolic INTO unatupla;

                   END LOOP;
                   CLOSE ccargolic;
                  
                   IF cont=0 THEN -- el afiliado tiene licencias en todos sus cargos activos
                       tienelic =true;
                   --DAni comento porq las personas con lsgh quedaban pasivas
                     /*  fechaultimoaporte =concat(date_part('month',fechaultimoaporte),'/10/', date_part('year',fechaultimoaporte));*/
                        fechaultimoaporte =concat('10/',date_part('month',fechaultimoaporte),'/',  date_part('year',fechaultimoaporte));
                    END IF; 
                 END IF;
             END IF;
             IF (nullvalue(fechaultimoaporte)) THEN
                       IF rpersona.barra = 34 THEN
                           /*  Dani  reemplaza 11072023 la linea por lo conversado con Matias. Becarios tienen fechafinos=mes ingreso aporte+ 1 mes
                          fechaSalida = datosbecarios.iniMasAntiguo;*/
                           
                           fechaSalida =concat('10/',date_part('month',pfechaactual),'/',  date_part('year',pfechaactual))::date+ interval '2 month'; 
                       ELSE
                            fechaSalida = datosCargo.iniMasAntiguo;
                       END IF;
                      
                       stipoinforme = 'FALTA ULTIMO APORTE';
                      SELECT INTO resultado2 *  FROM agregareninformev2(stipoinforme,nroinforme,pnrodoc,ptipodoc);
             ELSE
             /* Alguna Vez se recibio un aporte */
                      SELECT INTO cantaportesult3meses * FROM ultimostresaporterecibido(pnrodoc,ptipodoc,pfechaactual);
                       
                      IF(cantaportesult3meses >= 4 ) THEN
                                IF tienelic THEN
                                     fechaSalida = fechaultimoaporte + interval '1 month';
                                 ELSE
                                     if (rpersona.barra = 34) THEN
                                                fechaSalida = datosbecarios.finMasNuevo::date + '3 month'::interval;
                                     ELSE
                                                fechaSalida = datosCargo.finMasNuevo::date + '3 month'::interval;
                                     END IF;
                                 END IF;
                      END IF;
                      IF (cantaportesult3meses = 3 ) THEN
                         IF tienelic THEN
                              fechaSalida =fechaultimoaporte + interval '1 month';
                         ELSE
                             fechaSalida =pfechaactual + '2 month'::interval;
                         END IF;
                         stipoinforme = 'FALTAN APORTES';
                         SELECT INTO resultado2 *  FROM agregareninformev2(stipoinforme,nroinforme,pnrodoc,ptipodoc);

                      END IF;
                      IF (cantaportesult3meses = 2 ) THEN
                            IF tienelic THEN
                              fechaSalida =fechaultimoaporte + interval '1 month';
                         ELSE
                             fechaSalida =pfechaactual + '1 month'::interval;
                         END IF;
                         stipoinforme = 'FALTAN APORTES';
                         SELECT INTO resultado2 *  FROM agregareninformev2(stipoinforme,nroinforme,pnrodoc,ptipodoc);

                       END IF;
                       IF (cantaportesult3meses = 1 OR cantaportesult3meses = 0) THEN
                           IF tienelic THEN
                                 fechaSalida = fechaultimoaporte + interval '1 month';
                           ELSE
                                 SELECT INTO fechafinobrasoc *  FROM calcularfechafinos(pnrodoc,ptipodoc,fechaultimoaporte);
                                 fechaSalida =fechafinobrasoc;
                                 stipoinforme = 'FALTAN APORTES';
                                 SELECT INTO resultado2 *  FROM agregareninformev2(stipoinforme,nroinforme,pnrodoc,ptipodoc);
                           END IF;
                        END IF;

               END IF;

ELSE
-- No existe una designacion Vigante o se trata de un jubilado pensionado o becario

RAISE NOTICE 'Estoy en el No hay designacion vigente( fechaultimoaporte %)', fechaultimoaporte;
   

     IF( NOT nullvalue(fechaultimoaporte) AND
         date_trunc('month',fechaultimoaporte) >= date_trunc('month',pfechaactual-30)) THEN
         stipoinforme = 'NOEXISTELABORAL';
         SELECT INTO resultado2 * FROM agregareninformev2(stipoinforme,nroinforme,pnrodoc,ptipodoc);
         IF  (rpersona.barra=35 OR rpersona.barra = 36  OR rpersona.barra=34) THEN
              IF(rpersona.barra=34 ) THEN
                  fechaSalida = fechaultimoaporte + interval '3 month';
              ELSE
                /*Dani modifico 19042024 para que la fechafinos de los adherentes sea 30 de cada mes por pedido de Gerencia*/
                  --fechaSalida = fechaultimoaporte + interval '1 month';
                
      --select concat('01/',date_part('month','2024-01-10'::date),'/',  date_part('year','2024-01-10'::date))::date + interval '2 month' - interval '1 day'
       fechaSalida=concat('01/',date_part('month',fechaultimoaporte),'/',date_part('year',fechaultimoaporte))::date + interval '2 month' - interval '1 day';
           
               END IF;
                  
         ELSE
                  fechaSalida = fechaultimoaporte::date + '3 month'::interval;
         END IF;

     ELSE
         
          IF( NOT nullvalue(fechaultimoaporte)) THEN
             IF  (rpersona.barra=35  OR rpersona.barra = 36 ) THEN
                 --     fechaSalida = fechaultimoaporte ::date + '1 month'::interval;
                               
/*Dani modifico 19042024 para que la fechafinos de los adherentes sea 30 de cada mes por pedido de Gerencia*/
        fechaSalida=concat('01/',date_part('month',fechaultimoaporte),'/',date_part('year',fechaultimoaporte))::date + interval '2 month' - interval '1 day';
      
              ELSE
                  fechaSalida = fechaultimoaporte ::date + '3 month'::interval;
              END IF;
          ELSE
             
          -- VER ESTE CASO, QUEDO MEDIO RARO puede ser que nunca tuvo un cargo
              SELECT INTO datosCargo  max(fechafinlab) as finMasNuevo, min(fechainilab)as iniMasAntiguo
              FROM cargo
              WHERE cargo.nrodoc = pnrodoc AND cargo.tipodoc = ptipodoc;
               IF FOUND and  not nullvalue(datosCargo.finMasNuevo) THEN
                 RAISE NOTICE ' Estoy en el caso raro ( datosCargo.finMasNuevo %)', datosCargo.finMasNuevo;
                fechaSalida = datosCargo.finMasNuevo ;
               ELSE
                fechaSalida = NULL ;
               END IF;
              RAISE NOTICE ' Estoy en el caso raro ( datosCargo %)', datosCargo;
           END IF;
      END IF;
END IF;
END IF;

return fechaSalida;
end;
$function$
