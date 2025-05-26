CREATE OR REPLACE FUNCTION public.sys_asistencial_ampractconvval_coseguro(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
 

--VARIABLES
  vquery VARCHAR; 
  respuesta varchar;
  vcolumnas varchar;
  vwhere varchar;
  vreferencias varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- 1 - Para generar el valor de la asociacion
--MaLaPi 25-10-2022 Cambio por un sp que no crea la estructura de comparacion, pero es mas rapido
--SELECT INTO respuesta asistencial_cargarvaloresasocexpendio('{calcularexpendio=si}');
SELECT INTO respuesta asistencial_cargarvaloresasocexpendio_sincomparar('{calcularexpendio=si}');

RAISE NOTICE 'Termine el pasos 1,asistencial_cargarvaloresasocexpendio Respuesta: (%)',respuesta;

--2 -  -- Para cargar la configuracion del histórico de valores

INSERT INTO asistencial_practicavalores (idnomenclador, idcapitulo, idsubcapitulo, idpractica, apvpdescripcion, apvcantunidades, apviniciovigencia, apvidconvenio,apidasocconv,apvcodigososunc,apvdescripcionpractica,apvvalorfijo,apvfechaingreso,apvtexto) (
select c.idnomenclador, c.idcapitulo, c.idsubcapitulo, c.idpractica, c.pdescripcion as apvpdescripcion,1 as apvcantunidades,CASE WHEN nullvalue(c.fechainivigencia) THEN now() ELSE fechainivigencia END as apviniciovigencia, 323 as apvidconvenio, 154 as apidasocconv, concat(c.idnomenclador,'.',c.idcapitulo,'.',c.idsubcapitulo,'.',c.idpractica) as apvcodigososunc,pdescripcion as apvdescripcionpractica,valorexpendio as apvvalorfijo, now() as apvfechaingreso,c.asocinvolucradas
from comparacion_valores_practica as c
LEFT JOIN asistencial_practicavalores as a on (c.idnomenclador = a.idnomenclador and c.idcapitulo = a.idcapitulo and c.idsubcapitulo = a.idsubcapitulo and c.idpractica = a.idpractica and apidasocconv = 154 and apvidconvenio = 323   AND nullvalue(apvprocesado))
where nullvalue(idpracticavalores) AND idcvpprimary > 1

);

RAISE NOTICE 'Termine el pasos 2, cargue en la tabla asistencial_practicavalores : (%)',respuesta;

--3 - Para configurar el historico

SELECT INTO respuesta * from ampractconvval_configura();


RAISE NOTICE 'Termine el pasos 3, ampractconvval_configura : (%)',respuesta;

--4 -- Para calcular el valor para expendio

--select * from  calcularvalorespractica();
--select * from   calcularvalorespracticaxcategoria();

--Poner cuando tengas tiempo los pasos 1,2 y 3 en un sp que se llame sys_asistencial_ ampractconvval_coseguros()

--Solo va a quedar el paso 4 para ejectuarlo por fuera. 

vquery = concat('select * from  calcularvalorespractica();','select * from   calcularvalorespracticaxcategoria();');

RAISE NOTICE 'Termine los primeros 3 pasos, recordar que falta: (%)',vquery;



return respuesta;
END;
$function$
