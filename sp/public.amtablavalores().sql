CREATE OR REPLACE FUNCTION public.amtablavalores()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza la tabla de valores de un convenio
amtablavalores()
*/
DECLARE
	alta CURSOR FOR SELECT * FROM temptablavalores WHERE nullvalue(temptablavalores.error)
                                                         ORDER BY temptablavalores.idconvenio,
                                                                  temptablavalores.idtipounidad;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
	conv_ant bigint;
	unid_ant bigint;
	ident_tablavalor bigint;
	ident_tablavalor_ant bigint;
BEGIN
conv_ant = 0;
ident_tablavalor = 0;
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
IF (elem.idtipovalor <> 0) THEN
SELECT INTO aux * FROM convenio where convenio.idconvenio = elem.idconvenio;
IF NOT FOUND THEN
   UPDATE temptablavalores SET error = 'NOCONVENIO' WHERE temptablavalores.idconvenio = elem.idconvenio;
ELSE /*Si existe el convenio*/
conv_ant = elem.idconvenio;
ident_tablavalor_ant = elem.idtablavalor;
   SELECT INTO aux * FROM tipounidad where tipounidad.idtipounidad = elem.idtipounidad;
     IF NOT FOUND THEN
        UPDATE temptablavalores SET error = 'NOTIPOUNIDAD' WHERE temptablavalores.idtipounidad = elem.idtipounidad;
     ELSE /*Si existe el Tipo de Unidad*/
           SELECT INTO aux * FROM tablavalores where tablavalores.idconvenio = elem.idconvenio
                                                    AND tablavalores.idtipounidad = elem.idtipounidad
                                                    AND nullvalue(tablavalores.tvfinvigencia);
           IF FOUND THEN /*Si existe la unidad en la tabla de valores del convenio la da de baja  y se inserta otra*/
             UPDATE tablavalores SET tvfinvigencia = CURRENT_DATE
                                                    WHERE  tablavalores.idconvenio = elem.idconvenio
                                                    AND tablavalores.idtipounidad = elem.idtipounidad
                                                    AND nullvalue(tablavalores.tvfinvigencia);
          END IF;


           IF (conv_ant <> elem.idconvenio ) THEN
                      /*Todas la Unidades que no se hayan actualizado, deben ser dadas de baja, esto es para
                      el caso en el que se actualiza o ingresa mas de un convenio*/
                       UPDATE tablavalores SET tvfinvigencia = CURRENT_DATE
                                              WHERE  tablavalores.idtablavalor = ident_tablavalor_ant
                                                AND nullvalue(tablavalores.tvfinvigencia);
                       ident_tablavalor = 0;
           END IF;
           
           IF (ident_tablavalor = 0) THEN
                  Select INTO ident_tablavalor  * From nextval('tablavalores_idtablavalor_seq');
           END IF;
     
          INSERT INTO tablavalores (idconvenio,idtablavalor,idtipounidad,idtipovalor,tvinivigencia)
                                    VALUES (elem.idconvenio,ident_tablavalor,elem.idtipounidad,elem.idtipovalor,CURRENT_DATE);
          
          DELETE FROM temptablavalores where temptablavalores.idtablavalor = elem.idtablavalor
                                                    AND temptablavalores.idconvenio = elem.idconvenio
                                                    AND temptablavalores.idtipounidad = elem.idtipounidad;
      END IF; /*Si existe el Tipo de Unidad*/
END IF; /*Si existe el Convenio*/
ELSE
     DELETE FROM temptablavalores where temptablavalores.idtablavalor = elem.idtablavalor
                                                    AND temptablavalores.idconvenio = elem.idconvenio
                                                    AND temptablavalores.idtipounidad = elem.idtipounidad;

END IF; /*El valor de la Unidad es Distinto de Cero */
FETCH alta INTO elem;
END LOOP;
/*Todas la Unidades que no se hayan actualizado, deben ser dadas de baja, esto es para
el Ultimo convenio que se actualizo*/
   UPDATE tablavalores SET tvfinvigencia = CURRENT_DATE
                        WHERE  tablavalores.idtablavalor = ident_tablavalor_ant
                        AND nullvalue(tablavalores.tvfinvigencia);
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
