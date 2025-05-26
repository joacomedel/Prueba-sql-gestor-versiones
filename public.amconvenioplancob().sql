CREATE OR REPLACE FUNCTION public.amconvenioplancob()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza las Asociaciones de convnios que dan soporte a un plan de cobertura */
/*amconvenioplancob()*/
DECLARE
	alta refcursor;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
	verificar RECORD;
	errores boolean;
BEGIN
OPEN alta FOR SELECT * FROM tempconvenioplancob WHERE nullvalue(tempconvenioplancob.error)
                                            ORDER BY tempconvenioplancob.idplancoberturas;
FETCH alta INTO elem;
WHILE  found LOOP
errores = false;
       /*Verificar que exista la Asociacion de Convenios*/
SELECT INTO aux * FROM asocconvenio WHERE asocconvenio.idasocconv = elem.idasocconv
                                         AND nullvalue(asocconvenio.acfechafin);
  IF NOT FOUND THEN
     errores = true;
     UPDATE tempconvenioplancob SET error = 'NOASOCCONVENIO' WHERE tempconvenioplancob.idasocconv = elem.idasocconv;
  ELSE /*Si existe la Asociacione de Convenios*/
       /*verificar que exista el plan de cobertura*/
       Select INTO aux * From plancobertura WHERE plancobertura.idplancoberturas = elem.idplancoberturas;
       IF NOT FOUND THEN
           errores = TRUE;
           UPDATE tempconvenioplancob Set error = 'NOPLANCOBERTURA' WHERE tempconvenioplancob.idplancoberturas = elem.idplancoberturas;
       END IF;
       
 END IF;

IF NOT errores THEN /*No se ha producido ningun error*/
/*Verificar si el plan de covertura ya era soportado por la asociacion de convenios*/
SELECT INTO anterior * FROM convenioplancob WHERE convenioplancob.idasocconv = elem.idasocconv
                                                  AND convenioplancob.idplancoberturas = elem.idplancoberturas;
IF FOUND THEN
UPDATE convenioplancob SET cpcfechafin = CURRENT_DATE WHERE convenioplancob.idasocconv = elem.idasocconv
                                                           AND convenioplancob.idplancoberturas = elem.idplancoberturas;

END IF;
INSERT INTO convenioplancob (idplancobertura,idasocconv,idplancoberturas,cpcfechaini)
            VALUES (elem.idplancoberturas,elem.idasocconv,elem.idplancoberturas,elem.cpcfechaini);
DELETE FROM tempconvenioplancob WHERE tempconvenioplancob.idasocconv = elem.idasocconv
                                      AND tempconvenioplancob.idplancoberturas = elem.idplancoberturas
                                      AND tempconvenioplancob.cpcfechaini = elem.cpcfechaini;
ELSE /*Se ha producido un error*/
/*Se re calcula es Cursor para que no tome las tuplas con error*/
CLOSE alta;
OPEN alta FOR SELECT * FROM tempconvenioplancob WHERE nullvalue(tempconvenioplancob.error)
                                            ORDER BY tempconvenioplancob.idplancoberturas;
END IF;
FETCH alta INTO elem;
errores = FALSE;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
