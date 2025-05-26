CREATE OR REPLACE FUNCTION public.cambiarestadojubpen(boolean, date, date, integer, character varying, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*cambiarestadojubpen(true,fechaini,fechafin,elem.idlaboral,elem.nroliq,elem.nrodoc,tdoc);
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
	/*La fecha fin en la Obra social es Siempre la fecha de fin  que me mandan por parametro*/
	UPDATE persona SET fechafinos = fechafin WHERE nrodoc= $6 AND persona.tipodoc = $7;
	/*Idem para los Beneficiarios solo que s toma la fecha de fin OS del Titular*/
	UPDATE persona SET fechafinos = fechafin WHERE nrodoc IN (SELECT nrodoc FROM benefsosunc WHERE nrodoctitu= $6 AND tipodoctitu = $7 AND estaactivo);
  		IF(fechafin < current_date) THEN /*Recordar que fechafin es la fechafinOS*/
  			/*Se pago con un mes o mas de demora el aporte, con lo cual corresponde PASIVO para el titular y sus beneficiarios*/
			 /*Se debe colocar en el informe de aportes no esperados con Estado Pasivo o Compensacion de Carencia*/
			   tipinf = 'MoraRegularizada';
               SELECT INTO resultado * FROM agregareninforme(tipinf,CAST(nroinf AS bigint),current_date,$4,$5,$6,CAST(per.barra AS smallint ));
               /*insertar al titular en aportes recibidos*/
  			   SELECT INTO resultado2 * FROM agregarentaporterecibido(per.nrodoc,per.barra,usu);
              
	    END IF;
	    IF(fechaini < current_date AND fechafin > current_date) THEN
        /*Pago normal*/
        SELECT INTO resultado2 * FROM agregarentaporterecibido(per.nrodoc,per.barra,usu);
   END IF;
     end if;
  return 'true';
end;
$function$
