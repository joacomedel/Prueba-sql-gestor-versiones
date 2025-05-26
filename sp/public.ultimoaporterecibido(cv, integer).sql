CREATE OR REPLACE FUNCTION public.ultimoaporterecibido(character varying, integer)
 RETURNS date
 LANGUAGE plpgsql
AS $function$/* Recibe como parametros el tipo y numero de documento
* Retorna el aporte del ultimo mes recibido con el siguiente formato : 01/mesAporte/añoAporte
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       datoPersona RECORD;
       aportePersona RECORD;
       fechaSalida date;
begin
/* Busco los datos de la persona*/

            SELECT INTO datoPersona *
            FROM public.persona WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;
            IF FOUND THEN
               /* Busco el utimo aporte recibido de un jubilado / pensionado*/
               IF(datoPersona.barra =35 OR datoPersona.barra =34 OR datoPersona.barra =36)THEN
                        IF (datoPersona.barra =35 or datoPersona.barra =36) THEN /* APORTE JUBILADO*/
                                 

                                       
                                       SELECT  INTO aportePersona   date_part('month',MAx(aportejubpen.fechainiaport) ::date) as mes, date_part('year',MAx(aportejubpen.fechainiaport) ::date) as anio
                                       FROM aportejubpen
                                       NATURAL JOIN aporte_pagado
                                       WHERE nrodoc=datoPersona.nrodoc and  tipodoc =datoPersona.tipodoc;
                                        IF FOUND AND not nullvalue(aportePersona.mes) AND not nullvalue(aportePersona.anio) THEN
                                          SELECT INTO fechaSalida  to_date(concat(aportePersona.mes ,'/10/', aportePersona.anio),'MM/DD/YYYY');
END IF;
                                 
                        END IF;
                     
                         IF (datoPersona.barra =34) THEN /* APORTE Becario*/
                                       SELECT  INTO aportePersona aporte.ano,MAX(aporte.mes) as mes
                                       FROM aporte_pagado as aporte
                                       JOIN afilibec ON aporte.idresolbe = afilibec.idresolbe
                                       WHERE afilibec.nrodoc=datoPersona.nrodoc and afilibec.tipodoc =datoPersona.tipodoc
                                       group BY aporte.ano
                                       ORDER BY aporte.ano DESC
                                       LIMIT 1;
                                       IF FOUND THEN
                                           SELECT INTO fechaSalida to_date(concat(aportePersona.mes ,'/10/', aportePersona.ano),'MM/DD/YYYY');
                                       END IF;
                         END IF;
                       
              
              ELSE
                     /* Busco el utimo aporte recibido del afiliado */
/*KR 22-10-18 Si el importe del aporte es 0, entonces es un aporte de licencias en los que el afiliado no ha venido a pagar el mes, sino que se carga el aporte pq vino en los dh. SP agregaraporteslicencia()*/
                    SELECT INTO aportePersona aporte.ano,MAX(aporte.mes) as mes
                    FROM aporte_pagado as aporte
                    JOIN cargo ON aporte.idlaboral = cargo.idcargo
                    WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc AND importe<>0
                    group BY aporte.ano
                    ORDER BY aporte.ano DESC
                    LIMIT 1;
                    IF FOUND THEN
                     SELECT INTO fechaSalida to_date(concat(aportePersona.mes , '/01/', aportePersona.ano),'MM/DD/YYYY');
                     SELECT INTO fechaSalida ((date_trunc('month', fechaSalida) + interval '1 month') - interval '1 day')::date;
                    END IF;
                END IF;
            END IF;
return fechaSalida;

end;
$function$
