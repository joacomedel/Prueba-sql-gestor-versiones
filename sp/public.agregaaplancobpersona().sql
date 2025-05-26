CREATE OR REPLACE FUNCTION public.agregaaplancobpersona()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza las personas a un plan de cobertura */
/*amplancobpersona()*/
DECLARE
	alta refcursor;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
	verificar RECORD;
	plancob   RECORD;
	tipodeplan RECORD;
	cantdias integer;
	errores boolean;
BEGIN



OPEN alta FOR SELECT * FROM tempplancobpersona WHERE nullvalue(tempplancobpersona.error)
                                            ORDER BY tempplancobpersona.idplancoberturas;
FETCH alta INTO elem;
WHILE  found LOOP
errores = false;
/*Verificar que exista la persona*/
   Select INTO aux * FROM persona WHERE persona.tipodoc = elem.tipodoc
                                        AND persona.nrodoc = elem.nrodoc;
   IF NOT FOUND THEN
      errores = TRUE;
      UPDATE tempplancobpersona Set error = 'NOPERSONA' WHERE tempplancobpersona.tipodoc = elem.tipodoc
                                                        AND tempplancobpersona.nrodoc = elem.nrodoc;
   ELSE
    /*Verifica que el plan de cobertura exista*/
       Select INTO plancob * From plancobertura WHERE plancobertura.idplancoberturas = elem.idplancoberturas;
       IF NOT FOUND THEN
           errores = TRUE;
           UPDATE tempplancobpersona Set error = 'NOPLANCOBERTURA' WHERE tempplancobpersona.idplancoberturas = elem.idplancoberturas;
       END IF;
   END IF;



IF NOT errores THEN /*No se ha producido ningun error*/
SELECT INTO anterior * FROM plancobpersona WHERE plancobpersona.nrodoc = elem.nrodoc
                                                 AND plancobpersona.tipodoc = elem.tipodoc
                                                 AND plancobpersona.idplancoberturas = elem.idplancoberturas;
IF FOUND THEN /*SI Ya existe, se inserta como borrado y se vuelve a insertar */
INSERT INTO bplancobpersona (nrodoc,tipodoc,pcpdiagnostico,pcplugarinternacion,pcpprestador,pcpfechaalta,
                            pcpdetalleinforme,pcppresinforme,pcptipointernacion,pcpcantdias,idplancoberturas,
                            fechaborrado,pcpfechaingreso)
                    VALUES(anterior.nrodoc,anterior.tipodoc,anterior.pcpdiagnostico,anterior.pcplugarinternacion,anterior.pcpprestador,anterior.pcpfechaalta,
                            anterior.pcpdetalleinforme,anterior.pcppresinforme,anterior.pcptipointernacion,anterior.pcpcantdias,anterior.idplancoberturas,
                            CURRENT_TIMESTAMP,anterior.pcpfechaingreso);

DELETE FROM plancobpersona WHERE plancobpersona.nrodoc = elem.nrodoc
                                 AND plancobpersona.tipodoc = elem.tipodoc
                                 AND plancobpersona.idplancoberturas = elem.idplancoberturas;


END IF;
SELECT INTO tipodeplan * From tipoplancob WHERE tipoplancob.idtipoplancob = plancob.idtipoplan;
cantdias = 0;
IF tipodeplan.tpdescripcion = 'GENERAL INTERNACION' THEN
IF nullvalue(elem.pcpcantdias) THEN
   cantdias = tipodeplan.tpcantdiasinternacion;
 ELSE
   cantdias = elem.pcpcantdias;
END IF;
ELSE
   cantdias = elem.pcpcantdias;
END IF;

INSERT INTO plancobpersona (idplancobertura,nrodoc,tipodoc,pcpdiagnostico,pcplugarinternacion,pcpprestador
                           ,pcpfechaalta,pcpdetalleinforme,pcppresinforme,pcptipointernacion,pcpcantdias,
                           idplancoberturas,pcpfechaingreso)
            VALUES (elem.idplancoberturas,elem.nrodoc,elem.tipodoc,elem.pcpdiagnostico,elem.pcplugarinternacion,
                   elem.pcpprestador,elem.pcpfechaalta,elem.pcpdetalleinforme,elem.pcppresinforme,elem.pcptipointernacion,
                   cantdias,elem.idplancoberturas,elem.pcpfechaingreso);
DELETE FROM tempplancobpersona WHERE tempplancobpersona.idplancoberturas = elem.idplancoberturas
                                     AND tempplancobpersona.nrodoc = elem.nrodoc
                                     AND tempplancobpersona.tipodoc = elem.tipodoc
                                     AND tempplancobpersona.pcpfechaingreso = elem.pcpfechaingreso;

ELSE /*Se ha producido un error*/
/*Se re calcula es Cursor para que no tome las tuplas con error*/
CLOSE alta;
OPEN alta FOR SELECT * FROM tempplancobpersona WHERE nullvalue(tempplancobpersona.error)
                                            ORDER BY tempplancobpersona.idplancoberturas;
END IF;
FETCH alta INTO elem;
errores = FALSE;
END LOOP;
CLOSE alta;
resultado = 'true';
RETURN resultado;
END;
$function$
