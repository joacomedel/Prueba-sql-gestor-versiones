CREATE OR REPLACE FUNCTION public.ultimostresaporterecibido(character varying, integer, date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Recibe como parametros el tipo y numero de documento
* Retorna la cantidad de aportes recibidos en los ultimos 3 meses para los jubilados,
* pues el aporte del jubilado se abona por adelantado
* y para el resto, de los ultimos 4 meses, pues el aporte se paga
* a mes vencido
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       pfecha alias for $3;
       datoPersona RECORD;
       aportePersona RECORD;
       caru3meses integer;
       fechafinlicencia date;
       fechaverificar date;
begin

fechaverificar = date_trunc('month',pfecha)::date+1;

/* Busco los datos de la persona*/

            SELECT INTO datoPersona *
            FROM public.persona WHERE persona.nrodoc=pnrodoc and persona.tipodoc=ptipodoc;
            IF FOUND THEN
               /* Busco el utimo aporte recibido de un jubilado / pensionado*/
               IF (datoPersona.barra =35)OR(datoPersona.barra =36) THEN
                    
                    SELECT INTO caru3meses count(*) as cantidad
                     FROM (
                    SELECT  aporte.ano,aporte.mes
                    FROM aporte_pagado as aporte
                    JOIN afiljub ON aporte.idlaboral = afiljub.idcertpers
                    WHERE afiljub.nrodoc=datoPersona.nrodoc and afiljub.tipodoc =datoPersona.tipodoc
                   AND ((aporte.ano = date_part('year',fechaverificar::date) AND aporte.mes = date_part('month',fechaverificar::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-30)::date) AND aporte.mes = date_part('month',(fechaverificar-30)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-60)::date) AND aporte.mes = date_part('month',(fechaverificar-60)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-90)::date) AND aporte.mes = date_part('month',(fechaverificar-90)::date))
                                 )
                    group BY aporte.ano,aporte.mes
                    UNION
                    SELECT aporte.ano,aporte.mes
                            FROM aporte_pagado as aporte JOIN cargo ON aporte.idlaboral = cargo.idcargo
                               WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc
                               AND ((aporte.ano = date_part('year',fechaverificar::date) AND aporte.mes = date_part('month',fechaverificar::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-30)::date) AND aporte.mes = date_part('month',(fechaverificar-30)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-60)::date) AND aporte.mes = date_part('month',(fechaverificar-60)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-90)::date) AND aporte.mes = date_part('month',(fechaverificar-90)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-120)::date) AND aporte.mes = date_part('month',(fechaverificar-120)::date))
                                   )
                             group BY aporte.ano,aporte.mes
                         ) as temporales;

                ELSE
                    IF (datoPersona.barra =34) THEN
                                SELECT INTO caru3meses count(*) as cantidad
                                FROM (
                                     SELECT aporte.ano,aporte.mes
                                     FROM aporte_pagado as aporte NATURAL JOIN afilibec
                                     WHERE afilibec.nrodoc=datoPersona.nrodoc AND afilibec.tipodoc=1
                                     AND ((aporte.ano = date_part('year',fechaverificar::date) AND aporte.mes = date_part('month',fechaverificar::date))
                                     OR (aporte.ano = date_part('year',(fechaverificar-30)::date) AND aporte.mes = date_part('month',(fechaverificar-30)::date))
                                     OR (aporte.ano = date_part('year',(fechaverificar-60)::date) AND aporte.mes = date_part('month',(fechaverificar-60)::date))
                                     OR (aporte.ano = date_part('year',(fechaverificar-90)::date) AND aporte.mes = date_part('month',(fechaverificar-90)::date))
                                )
                                group BY aporte.ano,aporte.mes
                                ) as temporales;

                    ELSE

                              SELECT INTO fechafinlicencia fechafinlic
                              FROM licsinhab
                              NATURAL JOIN cargo
                              NATURAL JOIN persona
                              WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc;
                              IF (FOUND) THEN -- Tiene una licencia
                                         IF(fechafinlicencia::date > pfecha) THEN  --lic vigente
                                                          SELECT INTO caru3meses count(*) as cantidad
                                                          FROM (
                                                                   SELECT aporte.ano,aporte.mes
                                                                   FROM aporte_pagado as aporte JOIN cargo ON aporte.idlaboral = cargo.idcargo
                                                                   WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc
                                                                         AND ((aporte.ano = date_part('year',fechaverificar::date) AND aporte.mes = date_part('month',fechaverificar::date))
                                                                         OR (aporte.ano = date_part('year',(fechaverificar-30)::date) AND aporte.mes = date_part('month',(fechaverificar-30)::date))
                                                                         OR (aporte.ano = date_part('year',(fechaverificar-60)::date) AND aporte.mes = date_part('month',(fechaverificar-60)::date))
                                                                         OR (aporte.ano = date_part('year',(fechaverificar-90)::date) AND aporte.mes = date_part('month',(fechaverificar-90)::date))
                                                                          )
                                                          group BY aporte.ano,aporte.mes
                                                          ) as temporales;

                                          ELSE -- lic no esta vigente
                                               /* Busco el utimo aporte recibido del afiliado */
                                               SELECT INTO caru3meses count(*) as cantidad
                                               FROM (
                                                    SELECT aporte.ano,aporte.mes
                                                    FROM aporte_pagado as aporte JOIN cargo ON aporte.idlaboral = cargo.idcargo
                                                    WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc
                                                          AND ((aporte.ano = date_part('year',fechaverificar::date) AND aporte.mes = date_part('month',fechaverificar::date))
                                                          OR (aporte.ano = date_part('year',(fechaverificar-30)::date) AND aporte.mes = date_part('month',(fechaverificar-30)::date))
                                                          OR (aporte.ano = date_part('year',(fechaverificar-60)::date) AND aporte.mes = date_part('month',(fechaverificar-60)::date))
                                                          OR (aporte.ano = date_part('year',(fechaverificar-90)::date) AND aporte.mes = date_part('month',(fechaverificar-90)::date))
                                                          OR (aporte.ano = date_part('year',(fechaverificar-120)::date) AND aporte.mes = date_part('month',(fechaverificar-120)::date))
                                                          )
                                                    group BY aporte.ano,aporte.mes
                                                    ) as temporales;
                                          END IF;

                         ELSE -- No tiene licencia
                              /* Busco el utimo aporte recibido del afiliado */
                             SELECT INTO caru3meses count(*) as cantidad
                             FROM (
                                  SELECT aporte.ano,aporte.mes
                                  FROM aporte_pagado as aporte JOIN cargo ON aporte.idlaboral = cargo.idcargo
                                  WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc  
                                AND ((aporte.ano = date_part('year',fechaverificar::date) AND aporte.mes = date_part('month',fechaverificar::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-30)::date) AND aporte.mes = date_part('month',(fechaverificar-30)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-60)::date) AND aporte.mes = date_part('month',(fechaverificar-60)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-90)::date) AND aporte.mes = date_part('month',(fechaverificar-90)::date))
                                      OR (aporte.ano = date_part('year',(fechaverificar-120)::date) AND aporte.mes = date_part('month',(fechaverificar-120)::date))
                              )
                                  group BY aporte.ano,aporte.mes
                                  ) as temporales;
                         END IF;
                    END IF;
                END IF;
            END IF;
return caru3meses;

end;
$function$
