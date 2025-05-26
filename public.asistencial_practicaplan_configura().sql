CREATE OR REPLACE FUNCTION public.asistencial_practicaplan_configura()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los datos de una nomenclador */
/*ampractconvval()*/
DECLARE
	alta refcursor; 
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	rconfiguracion RECORD;
	resultado boolean;
	idconvenio bigint;
	verificar RECORD;
	deno_anterior bigint;
	idpracticavalor bigint;
	errores boolean;
        rusuario RECORD; 
BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


--Arreglamos los valores por defecto

UPDATE asistencial_practicaplan SET ppcprioridad = 1 WHERE nullvalue(apcprocesado) AND nullvalue(ppcprioridad);
UPDATE asistencial_practicaplan SET serepite = true WHERE nullvalue(apcprocesado) AND nullvalue(serepite);
UPDATE asistencial_practicaplan SET ppcperiodo = 'a' WHERE nullvalue(apcprocesado) AND nullvalue(ppcperiodo);
UPDATE asistencial_practicaplan SET ppccantperiodos = 1 WHERE nullvalue(apcprocesado) AND nullvalue(ppccantperiodos);
UPDATE asistencial_practicaplan SET ppclongperiodo = 1 WHERE nullvalue(apcprocesado) AND nullvalue(ppclongperiodo);
UPDATE asistencial_practicaplan SET ppcperiodoinicial = 1 WHERE nullvalue(apcprocesado) AND nullvalue(ppcperiodoinicial);
UPDATE asistencial_practicaplan SET ppcperiodofinal = 1 WHERE nullvalue(apcprocesado) AND nullvalue(ppcperiodofinal);
UPDATE asistencial_practicaplan SET ppccantpracticaauditada = 1000 WHERE nullvalue(apcprocesado) AND nullvalue(ppccantpracticaauditada);

UPDATE asistencial_practicaplan SET ppcoberturaamuc = 0.2 WHERE nullvalue(apcprocesado) AND nullvalue(ppcoberturaamuc);

--MaLaPi 25-10-2022 Lo saco porque no todas las practicas tienen 4 caracteres
--UPDATE asistencial_practicaplan SET idpractica = lpad(idpractica, 4, '0') WHERE nullvalue(apcprocesado) AND LENGTH(idpractica) < 4;
--UPDATE asistencial_practicaplan SET idsubcapitulo = lpad(idsubcapitulo, 2, '0') WHERE nullvalue(apcprocesado) AND LENGTH(idsubcapitulo) < 2;
--UPDATE asistencial_practicaplan SET idcapitulo = lpad(idcapitulo, 2, '0') WHERE nullvalue(apcprocesado) AND LENGTH(idcapitulo) < 2;
--UPDATE asistencial_practicaplan SET idnomenclador = lpad(idnomenclador, 2, '0') WHERE nullvalue(apcprocesado) AND LENGTH(idnomenclador) < 2;



--SELECT INTO rconfiguracion * FROM asistencial_practicaplan 
--				WHERE nullvalue(apcprocesado) 
--				AND not nullvalue(idnomenclador)
--				AND not nullvalue(idplancoberturas)
--                                ORDER BY asistencial_practicaplan.idplancoberturas;
--IF FOUND THEN 
--Backup de lo que voy a cambiar. 
--INSERT INTO practicaplanborradas (idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, --ppcprioridad, idconfiguracion, serepite, ppcperiodoinicial, ppcperiodofinal) (
--SELECT idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion, --serepite, ppcperiodoinicial, ppcperiodofinal
--FROM practicaplan
--WHERE  idplancoberturas = rconfiguracion.idplancoberturas
--	AND idnomenclador = rconfiguracion.idnomenclador
--);
--
--DELETE FROM practicaplan
--WHERE  idplancoberturas = rconfiguracion.idplancoberturas
--	AND idnomenclador = rconfiguracion.idnomenclador; 
--END IF;

OPEN alta FOR SELECT * FROM  asistencial_practicaplan WHERE nullvalue(apcprocesado) 
                                            ORDER BY asistencial_practicaplan.idplancoberturas;
FETCH alta INTO elem;
WHILE  found LOOP
   Select INTO aux * FROM practica WHERE practica.idnomenclador = elem.idnomenclador
                                                  AND practica.idcapitulo = elem.idcapitulo
                                                  AND practica.idsubcapitulo = elem.idsubcapitulo
                                                  AND practica.idpractica  = elem.idpractica;
   IF NOT FOUND THEN
      errores = TRUE;
      UPDATE asistencial_practicaplan Set apperror = 'NOPRACTICA' WHERE asistencial_practicaplan.idnomenclador = elem.idnomenclador
                                                  AND asistencial_practicaplan.idcapitulo = elem.idcapitulo
                                                  AND asistencial_practicaplan.idsubcapitulo = elem.idsubcapitulo
                                                 AND asistencial_practicaplan.idpractica  = elem.idpractica;
    END IF;  
   Select INTO aux * From plancobertura WHERE plancobertura.idplancoberturas = elem.idplancoberturas;
   IF NOT FOUND THEN
        errores = TRUE;
        UPDATE asistencial_practicaplan Set apperror = 'NOPLANCOBERTURA' WHERE asistencial_practicaplan.idplancoberturas = elem.idplancoberturas;
   END IF;
   
IF NOT errores THEN 


IF elem.ppccantpracticanoauditada > 0 THEN


--Backup de lo que voy a cambiar. 
INSERT INTO practicaplanborradas (idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion, serepite, ppcperiodoinicial, ppcperiodofinal) (
SELECT idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion, serepite, ppcperiodoinicial, ppcperiodofinal
FROM practicaplan
WHERE  idplancoberturas = elem.idplancoberturas
	AND idnomenclador = elem.idnomenclador
        AND idcapitulo = elem.idcapitulo
        AND idsubcapitulo = elem.idsubcapitulo
        AND idpractica = elem.idpractica
        AND auditoria = FALSE
);

DELETE FROM practicaplan
WHERE  idplancoberturas = elem.idplancoberturas
	AND idnomenclador = elem.idnomenclador
        AND idcapitulo = elem.idcapitulo
        AND idsubcapitulo = elem.idsubcapitulo
        AND idpractica = elem.idpractica
        AND auditoria = FALSE; 



--Configuracion NO auditada
 INSERT INTO practicaplan(idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas
 , ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad
 , serepite, ppcperiodoinicial, ppcperiodofinal, ppcoberturaamuc, ppcoberturasosunc)
 VALUES(elem.idpractica, elem.idplancobertura, elem.idnomenclador, FALSE, elem.cobertura, elem.idcapitulo, elem.idsubcapitulo, elem.idplancoberturas
 , elem.ppccantpracticanoauditada, elem.ppcperiodo, elem.ppccantperiodos , elem.ppclongperiodo, elem.ppcprioridad
 , elem.serepite, elem.ppcperiodoinicial, elem.ppcperiodofinal, elem.ppcoberturaamuc, elem.ppcoberturasosunc);




 UPDATE asistencial_practicaplan SET idconfiguracionnoauditada = currval('practicaplan_idconfiguracion_seq'::regclass),apcprocesado = now()	  
 WHERE asistencial_practicaplan.idasistencial_practicaplan = elem.idasistencial_practicaplan;

END IF;

IF elem.ppccantpracticaauditada > 0 THEN

     
--Backup de lo que voy a cambiar. 
INSERT INTO practicaplanborradas (idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion, serepite, ppcperiodoinicial, ppcperiodofinal) (
SELECT idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas, ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad, idconfiguracion, serepite, ppcperiodoinicial, ppcperiodofinal
FROM practicaplan
WHERE  idplancoberturas = elem.idplancoberturas
	AND idnomenclador = elem.idnomenclador
        AND idcapitulo = elem.idcapitulo
        AND idsubcapitulo = elem.idsubcapitulo
        AND idpractica = elem.idpractica
        AND auditoria = TRUE
);

DELETE FROM practicaplan
WHERE  idplancoberturas = elem.idplancoberturas
	AND idnomenclador = elem.idnomenclador
        AND idcapitulo = elem.idcapitulo
        AND idsubcapitulo = elem.idsubcapitulo
        AND idpractica = elem.idpractica
        AND auditoria = TRUE; 



--Configuracion CON auditoria
 INSERT INTO practicaplan(idpractica, idplancobertura, idnomenclador, auditoria, cobertura, idcapitulo, idsubcapitulo, idplancoberturas
 , ppccantpractica, ppcperiodo, ppccantperiodos, ppclongperiodo, ppcprioridad
 , serepite, ppcperiodoinicial, ppcperiodofinal, ppcoberturaamuc, ppcoberturasosunc)
 VALUES(elem.idpractica, elem.idplancobertura, elem.idnomenclador, TRUE, elem.cobertura, elem.idcapitulo, elem.idsubcapitulo, elem.idplancoberturas
 , elem.ppccantpracticaauditada, elem.ppcperiodo, elem.ppccantperiodos , elem.ppclongperiodo, elem.ppcprioridad
 , elem.serepite, elem.ppcperiodoinicial, elem.ppcperiodofinal, elem.ppcoberturaamuc, elem.ppcoberturasosunc);
  
 UPDATE asistencial_practicaplan SET idconfiguracionauditada = currval('practicaplan_idconfiguracion_seq'::regclass),apcprocesado = now()	  
 WHERE asistencial_practicaplan.idasistencial_practicaplan = elem.idasistencial_practicaplan;
     
END IF;
END IF;

FETCH alta INTO elem;
errores = FALSE;
END LOOP;
CLOSE alta;
resultado = 'true';





RETURN resultado;
END;
$function$
