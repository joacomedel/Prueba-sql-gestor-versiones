CREATE OR REPLACE FUNCTION public.cambiarestado(boolean, date, date, integer, character varying, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*cambiarestado(true,fechaini,fechafin,elem.idlaboral,elem.nroliq,elem.nrodoc,tdoc);
$1 si es titular o Benef
$2 Fecha de Inicio laboral
$3 Feccha de Fin Laboral
$4 IdLaboral
$5 NroLiquidacion
$6 NroDoc
$7 TipoDoc*/
DECLARE
    benef CURSOR FOR SELECT * FROM persona WHERE nrodoc IN (SELECT nrodoc FROM benefsosunc WHERE nrodoctitu= $6 AND tipodoctitu = $7);
    ben record;
    per RECORD;
    verifica RECORD;
    rdatlab RECORD;
    resultado boolean;
    resultado2 boolean;
    fechafin DATE;
    fechaini DATE;
    usu varchar;
    tipinf varchar;
    liq RECORD;
    nroinf bigint;
BEGIN
/*Los estados se actualizan con el triggers que se dispara al actualizar la fechafinos por lo que
ya no se actualizan mas en este STORE*/
usu = 'MALAPI';
  SELECT INTO liq * FROM liquidacion WHERE liquidacion.nroliquidacion = $5;
  IF FOUND THEN
       nroinf = liq.anio * 100 + liq.mes;
  ELSE
       nroinf = extract(YEAR from CURRENT_DATE) * 100 + extract(MONTH from CURRENT_DATE);
  END IF;
  SELECT INTO per * FROM persona WHERE persona.nrodoc= $6 AND persona.tipodoc = $7;
  IF FOUND THEN
           fechafin = $3;
           fechaini = $2;
        IF per.barra = 35 OR per.barra = 36 THEN
  		
           SELECT INTO resultado * FROM cambiarestadojubpen(true,fechaini,fechafin,$4,$5,$6,$7);
  		ELSE -- Licencia
  		
  	   SELECT INTO resultado * FROM cambiarestadolicsinhab(true,fechaini,fechafin,$4,$5,$6,$7);
  	
		END IF;
     end if;

  return 'true';
end;
$function$
