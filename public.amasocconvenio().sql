CREATE OR REPLACE FUNCTION public.amasocconvenio()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza los los convenios de una asociacion
amasocconvenio()
*/
DECLARE
	alta CURSOR FOR SELECT * FROM tempasocconvenio WHERE nullvalue(tempasocconvenio.error)
                                                         ORDER By tempasocconvenio.acdecripcion;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	aux2 RECORD;
	resultado boolean;
	idasos bigint;
	deno_anterior varchar;
	descip varchar;
BEGIN
deno_anterior = '';
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP

  SELECT INTO aux * FROM convenio where convenio.idconvenio = elem.idconvenio;
     IF NOT FOUND THEN
        UPDATE tempasocconvenio SET error = 'NOCONVENIO' WHERE tempasocconvenio.idconvenio = elem.idconvenio;
     ELSE /*Si existe el convenio*/
           /*Verifico si ya existe la Asociacion*/
           descip = elem.acdecripcion;
          SELECT INTO aux2 * FROM asocconvenio WHERE asocconvenio.acdecripcion = elem.acdecripcion
                                                     AND (nullvalue(asocconvenio.acfechafin)
                                                         OR (asocconvenio.acfechafin <= CURRENT_DATE));
          IF FOUND THEN
               UPDATE asocconvenio SET acfechaini = elem.acfechaini
                                       ,asdescripext = elem.asdescripext
                                       WHERE asocconvenio.acdecripcion = elem.acdecripcion
                                        AND (nullvalue(asocconvenio.acfechafin)
                                                         OR (asocconvenio.acfechafin <= CURRENT_DATE));
               idasos = aux2.idasocconv;
          ELSE
              IF  deno_anterior <> elem.acdecripcion THEN /*Se cambia de Asociacion */
                  deno_anterior = elem.acdecripcion;
                  Select INTO idasos  * From nextval('asocconvenio_idasocconv_seq');
              END IF;
            INSERT INTO asocconvenio (idasocconv,acdecripcion,idconvenio,acfechaini,asdescripext,acfechafin)
                                    VALUES (idasos,elem.acdecripcion,elem.idconvenio,elem.acfechaini,elem.asdescripext,elem.acfechafin);
          END IF;
          
          SELECT INTO aux * FROM asocconvenio WHERE asocconvenio.idconvenio = elem.idconvenio
                                                    AND asocconvenio.acdecripcion = elem.acdecripcion
                                                    AND (nullvalue(asocconvenio.acfechafin)
                                                         OR (asocconvenio.acfechafin <= CURRENT_DATE));
          /*Verifico si el Convenio ya pertenece a la Asociacion*/
          IF NOT FOUND THEN
          /*Verifico si alguna ves Existio en la Asociacion*/
              SELECT INTO aux * FROM asocconvenio WHERE asocconvenio.idconvenio = elem.idconvenio
                                                       AND asocconvenio.acdecripcion = elem.acdecripcion;
            IF NOT FOUND THEN
             INSERT INTO asocconvenio (idasocconv,acdecripcion,idconvenio,acfechaini,asdescripext,acfechafin)
                                    VALUES (idasos,elem.acdecripcion,elem.idconvenio,elem.acfechaini,elem.asdescripext,elem.acfechafin);
             ELSE
                 UPDATE asocconvenio SET acfechaini = elem.acfechaini
                                         ,acfechafin = elem.acfechafin
                                  WHERE asocconvenio.idconvenio = elem.idconvenio
                                  AND asocconvenio.acdecripcion = elem.acdecripcion;
             END IF;
          ELSE
              UPDATE asocconvenio SET acfechaini = elem.acfechaini
                                      ,acfechafin = elem.acfechafin
                                  WHERE asocconvenio.idconvenio = elem.idconvenio
                                        AND asocconvenio.acdecripcion = elem.acdecripcion
                                        AND (nullvalue(asocconvenio.acfechafin)
                                              OR (asocconvenio.acfechafin <= CURRENT_DATE));
          END IF;
      END IF; /*Si existe el convenio*/
FETCH alta INTO elem;
END LOOP;
UPDATE asocconvenio SET acfechafin = CURRENT_DATE
                    WHERE asocconvenio.acdecripcion = descip AND
                    (asocconvenio.idconvenio) not IN (Select  tempasocconvenio.idconvenio
                                                       FROM tempasocconvenio
                                                       WHERE nullvalue(tempasocconvenio.error));
                          
DELETE FROM tempasocconvenio WHERE nullvalue(tempasocconvenio.error);

CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
