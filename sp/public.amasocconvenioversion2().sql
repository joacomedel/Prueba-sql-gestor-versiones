CREATE OR REPLACE FUNCTION public.amasocconvenioversion2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los los convenios de una asociacion
amasocconvenio()
Se Modifica 14-02-2007 para que al modificar la asociacion no cree una nueva sino que actualice
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
        vidusuario INTEGER;
BEGIN
deno_anterior = '';
vidusuario =sys_dar_usuarioactual();
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP

  SELECT INTO aux * FROM convenio where convenio.idconvenio = elem.idconvenio;
     IF NOT FOUND THEN
        UPDATE tempasocconvenio SET error = 'NOCONVENIO' WHERE tempasocconvenio.idconvenio = elem.idconvenio;
     ELSE /*Si existe el convenio*/
           /*Verifico si ya existe la Asociacion*/
          descip = elem.acdecripcion;
          SELECT INTO aux2 * FROM asocconvenio WHERE asocconvenio.idasocconv = elem.idasocconv;
          IF FOUND THEN
               UPDATE asocconvenio SET acfechaini = elem.acfechaini
                                       ,asdescripext = elem.asdescripext
                                       ,acfechafin = elem.acfechafin
                                       ,acdecripcion = elem.acdecripcion
                                       ,acidusuariomodifica =vidusuario
                                       WHERE asocconvenio.idasocconv = elem.idasocconv;
                                        
               idasos = aux2.idasocconv;
               deno_anterior = elem.acdecripcion;
          ELSE
              IF  deno_anterior <> elem.acdecripcion THEN /*Se cambia de Asociacion */
                  deno_anterior = elem.acdecripcion;
                  Select INTO idasos  * From nextval('asocconvenio_idasocconv_seq');
              END IF;
            INSERT INTO asocconvenio (idasocconv,acdecripcion,idconvenio,acfechaini,asdescripext,acfechafin,acidusuariocarga)
                                    VALUES (idasos,elem.acdecripcion,elem.idconvenio,elem.acfechaini,elem.asdescripext,elem.acfechafin,vidusuario);
          END IF;
          
          SELECT INTO aux * FROM asocconvenio WHERE asocconvenio.idconvenio = elem.idconvenio
                                                    AND asocconvenio.idasocconv = idasos;
          /*Verifico si el Convenio ya pertenece a la Asociacion*/
          IF NOT FOUND THEN
             INSERT INTO asocconvenio (idasocconv,acdecripcion,idconvenio,acfechaini,asdescripext,acfechafin,acidusuariocarga)
                                    VALUES (idasos,elem.acdecripcion,elem.idconvenio,elem.acfechaini,elem.asdescripext,elem.acfechafin,vidusuario);
             ELSE
                 UPDATE asocconvenio SET acfechaini = elem.acfechaini
                                         ,acfechafin = elem.acfechafin
                                         ,acidusuariomodifica =vidusuario
                                         --,idasocconv = idasos
                                  WHERE asocconvenio.idconvenio = elem.idconvenio
                                  AND asocconvenio.idasocconv = idasos;
             END IF;
         END IF; /*Si existe el convenio*/
FETCH alta INTO elem;
END LOOP;

DELETE FROM asocconvenio WHERE asocconvenio.acdecripcion = descip AND
                    (asocconvenio.idconvenio) not IN (Select  tempasocconvenio.idconvenio
                                                       FROM tempasocconvenio
                                                       WHERE nullvalue(tempasocconvenio.error));

DELETE FROM tempasocconvenio WHERE nullvalue(tempasocconvenio.error);

CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
