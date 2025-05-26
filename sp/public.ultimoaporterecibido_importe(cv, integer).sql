CREATE OR REPLACE FUNCTION public.ultimoaporterecibido_importe(character varying, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* Recibe como parametros el tipo y numero de documento
* Retorna el aporte del ultimo aporte recibido
*/
DECLARE
       pnrodoc alias for $1;
       ptipodoc alias for $2;
       datoPersona RECORD;
       aportePersona RECORD;
       raporte public.aporte%rowtype;

begin
/* Busco los datos de la persona*/

            SELECT INTO datoPersona *
            FROM public.persona
            WHERE persona.nrodoc=pnrodoc
                  AND persona.tipodoc=ptipodoc;
            IF FOUND THEN
               /* Busco el utimo aporte recibido de un jubilado / pensionado*/
               IF(datoPersona.barra =35 OR datoPersona.barra =34 OR datoPersona.barra =36)THEN
                        IF (datoPersona.barra =35 or datoPersona.barra =36) THEN /* APORTE JUBILADO*/
                                   SELECT INTO raporte aporte.*
                                   FROM aporte
                                      NATURAL JOIN (
                                       SELECT   aporte.ano,MAX(aporte.mes) as mes,nrodoc,tipodoc
                                       FROM aporte
                                       JOIN afiljub ON aporte.idcertpers = afiljub.idcertpers
                                       WHERE afiljub.nrodoc=datoPersona.nrodoc
                                              and afiljub.tipodoc =datoPersona.tipodoc
                                       group BY aporte.ano,nrodoc,tipodoc
                                       ORDER BY aporte.ano DESC
                                       LIMIT 1
                                       ) as datosaporte
                                       WHERE nrodoc=datoPersona.nrodoc
                                       AND tipodoc =datoPersona.tipodoc;
                        END IF;
                         IF (datoPersona.barra =34) THEN /* APORTE Becario*/
                                      /* SELECT  INTO aportePersona aporte.ano,MAX(aporte.mes) as mes
                                       FROM aporte
                                       JOIN afilibec ON aporte.idresolbe = afilibec.idresolbe
                                       WHERE afilibec.nrodoc=datoPersona.nrodoc and afilibec.tipodoc =datoPersona.tipodoc
                                       group BY aporte.ano
                                       ORDER BY aporte.ano DESC
                                       LIMIT 1;
                                       fechaSalida = concat(aportePersona.mes ,'/10/', aportePersona.ano);*/
                         END IF;

              ELSE
                     /* Busco el utimo aporte recibido del afiliado */
                   /* SELECT INTO aportePersona aporte.ano,MAX(aporte.mes) as mes
                    FROM aporte
                    JOIN cargo ON aporte.idlaboral = cargo.idcargo
                    WHERE cargo.nrodoc=datoPersona.nrodoc AND cargo.tipodoc=datoPersona.tipodoc
                    group BY aporte.ano
                    ORDER BY aporte.ano DESC
                    LIMIT 1;
                    fechaSalida = concat(aportePersona.mes , '/01/', aportePersona.ano);
                    fechaSalida = ((date_trunc('month', fechaSalida) + interval '1 month') - interval '1 day')::date;*/

                END IF;
            END IF;

--RETURN NEXT raporte.importe::double precision;
RETURN raporte.importe;
end;
$function$
