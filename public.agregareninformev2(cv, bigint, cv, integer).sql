CREATE OR REPLACE FUNCTION public.agregareninformev2(character varying, bigint, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
$1 TipoInforme
$2 NroInforme
$3 dni
$4 tipooc
*/
DECLARE
    rinforme RECORD;
    usu varchar;
    ptipoinforme alias for $1;
	pnroinforme alias for $2;
   	pdni alias for $3;
	ptipodoc alias for $4;
	raporte RECORD;
	rpersona RECORD;
	rtipoinforme RECORD;
BEGIN

SELECT INTO rtipoinforme * FROM tipoinforme WHERE tipoinforme.tipoinforme = ptipoinforme;


SELECT INTO rpersona * FROM persona
WHERE persona.nrodoc = pdni AND persona.tipodoc= ptipodoc;

IF rtipoinforme.esfaltante THEN

 SELECT INTO rinforme * FROM infaportesfaltantes WHERE infaportesfaltantes.nrodoc = pdni
                                                  AND infaportesfaltantes.barra = rpersona.barra
                                                  AND infaportesfaltantes.tipoinforme = ptipoinforme
                                                  AND infaportesfaltantes.nrotipoinforme = pnroinforme;

     IF NOT FOUND THEN
        INSERT INTO infaportesfaltantes (tipoinforme,fechamodificacion,anio,mes,nrodoc,barra,tipodoc,nrotipoinforme) VALUES
        (ptipoinforme,CURRENT_DATE,date_part('year', CURRENT_DATE),date_part('month', CURRENT_DATE),pdni,rpersona.barra,ptipodoc,pnroinforme);

    end if;


ELSE
-- Se busca el ultimo aporte recibido para tomar el idlaboral y el nro de liquidacion
   IF (rpersona.barra = 35 OR rpersona.barra = 36) THEN
       SELECT INTO raporte *
       FROM aporte
       JOIN afiljub ON aporte.idlaboral = afiljub.idcertpers
       WHERE afiljub.nrodoc=pdni and afiljub.tipodoc =ptipodoc
       ORDER BY aporte.ano DESC,aporte.mes DESC
       LIMIT 1;
    
    ELSE
    
           SELECT INTO raporte * FROM aporte
           JOIN cargo ON cargo.idcargo = aporte.idlaboral
           WHERE cargo.nrodoc = pdni AND cargo.tipodoc = ptipodoc
           ORDER BY aporte.ano DESC,aporte.mes DESC
           LIMIT 1;

    END IF;
     SELECT INTO rinforme * FROM infaporrecibido WHERE infaporrecibido.nrodoc = pdni
                                                  AND infaporrecibido.barra = rpersona.barra
                                                  AND infaporrecibido.tipoinforme = ptipoinforme
                                                  AND infaporrecibido.nrotipoinforme = pnroinforme;

     IF NOT FOUND THEN
        IF nullvalue(raporte.idlaboral) THEN
        ---INSERT INTO infaporrecibido (tipoinforme,nrotipoinforme,fechmodificacion,nroliquidacion,nrodoc,barra)
        ---VALUES (ptipoinforme,pnroinforme,CURRENT_DATE,raporte.nroliquidacion,pdni,rpersona.barra);

        ELSE
        INSERT INTO infaporrecibido (tipoinforme,nrotipoinforme,fechmodificacion,idlaboral,nroliquidacion,nrodoc,barra)
        VALUES (ptipoinforme,pnroinforme,CURRENT_DATE,raporte.idlaboral,raporte.nroliquidacion,pdni,rpersona.barra);
        END IF;
    end if;
END IF;
return true;
END;
$function$
