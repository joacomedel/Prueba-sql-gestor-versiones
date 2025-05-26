CREATE OR REPLACE FUNCTION public.ampracticaplan()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza las practicas de un plan de cobertura */
/*ampracticaplan()*/
DECLARE
	alta refcursor; 
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
	verificar RECORD;
	errores boolean;
BEGIN
OPEN alta FOR SELECT * FROM temppracticaplan WHERE nullvalue(temppracticaplan.error)
                                            ORDER BY temppracticaplan.idplancoberturas;
FETCH alta INTO elem;
WHILE  found LOOP
/*Verificar que la practica exista*/
   Select INTO aux * FROM practica WHERE practica.idnomenclador = elem.idnomenclador
                                                  AND practica.idcapitulo = elem.idcapitulo
                                                  AND practica.idsubcapitulo = elem.idsubcapitulo
                                                  AND practica.idpractica  = elem.idpractica;
   IF NOT FOUND THEN
      errores = TRUE;
      UPDATE temppracticaplan Set error = 'NOPRACTICA' WHERE temppracticaplan.idnomenclador = elem.idnomenclador
                                                  AND temppracticaplan.idcapitulo = elem.idcapitulo
                                                  AND temppracticaplan.idsubcapitulo = elem.idsubcapitulo
                                                  AND temppracticaplan.idpractica  = elem.idpractica;
   ELSE /*Si existe la practica*/
   /*Verifica que el plan de cobertura exista*/
       Select INTO aux * From plancobertura WHERE plancobertura.idplancoberturas = elem.idplancoberturas;
       IF NOT FOUND THEN
           errores = TRUE;
           UPDATE temppracticaplan Set error = 'NOPLANCOBERTURA' WHERE temppracticaplan.idplancoberturas = elem.idplancoberturas;
       END IF;
   END IF;
 /*Si existe la practica*/ /*Si existe el plan de Cobertura*/
IF NOT errores THEN /*No se ha producido ningun error*/
 INSERT INTO practicaplan (idplancobertura,idplancoberturas,idnomenclador,idcapitulo,idsubcapitulo,idpractica,auditoria,cobertura,
            ppccantpractica,ppcperiodo,ppccantperiodos,ppclongperiodo,ppcprioridad)
 VALUES(aux.idplancoberturas,aux.idplancoberturas,elem.idnomenclador,elem.idcapitulo,elem.idsubcapitulo,
       elem.idpractica,elem.auditoria,elem.cobertura,elem.ppccantpractica,elem.ppcperiodo,elem.ppccantperiodos,
     elem.ppclongperiodo,elem.ppcprioridad);
 DELETE FROM temppracticaplan WHERE temppracticaplan.idconfiguracion = elem.idconfiguracion;
     

ELSE /*Se ha producido un error*/
/*Se re calcula es Cursor para que no tome las tuplas con error*/
CLOSE alta;
OPEN alta FOR SELECT * FROM temppracticaplan WHERE nullvalue(temppracticaplan.error)
                                             ORDER BY temppracticaplan.idplancoberturas;
END IF; 
FETCH alta INTO elem;
errores = FALSE;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
