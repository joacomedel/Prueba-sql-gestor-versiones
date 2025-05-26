CREATE OR REPLACE FUNCTION public.asistencial_nomenclador_verifica()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los datos de una nomenclador */
/**/
DECLARE
	alta refcursor; 
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	rconvenio RECORD;
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

--Por si usaron comas para los decimales en lugar de puntos, los arreglos
UPDATE asistencial_nomenclador SET anhonorario1=replace(anhonorario1,',','.'), anhonorario2=replace(anhonorario2,',','.'),anhonorario3 = replace(anhonorario3,',','.'),ancantidad1 = replace(ancantidad1,',','.'),ancantidad2 = replace(ancantidad2,',','.'),ancantidad3 = replace(ancantidad3,',','.')
,angastos2= replace(angastos2,',','.')
,ancantgastos2= replace(ancantgastos2,',','.')
,angastos3= replace(angastos3,',','.')
,ancantgastos3= replace(ancantgastos3,',','.')
,angastos4= replace(angastos4,',','.')
,ancantgastos4= replace(ancantgastos4,',','.')
,angastos5= replace(angastos5,',','.')
,ancantgastos5= replace(ancantgastos5,',','.')
WHERE nullvalue(anprocesado);
--Si las practicas estan en un solo bloque, las separo, siempre que no este cargado el nomenclador o el capitulo
UPDATE asistencial_nomenclador SET idnomenclador=t.idnomenclador,idcapitulo=t.idcapitulo,idsubcapitulo=t.idsubcapitulo,idpractica=t.idpractica
FROM (
select 
--lpad(idnomenclador,2,'0')  as idnomenclador,lpad(idcapitulo,2,'0')   as idcapitulo,lpad(idsubcapitulo,2,'0')  as idsubcapitulo,lpad(idpractica,2,'0')   as idpractica,idpracticavalores  
split_part(ancodigososunc,',',1) as idnomenclador
,split_part(ancodigososunc,',',2) as idcapitulo
,split_part(ancodigososunc,',',3) as idsubcapitulo
,split_part(ancodigososunc,',',4) as idpractica
,idasistencialnomenclador 
FROM asistencial_nomenclador
WHERE not nullvalue(ancodigososunc) 
) as t
WHERE t.idasistencialnomenclador = asistencial_nomenclador.idasistencialnomenclador
AND nullvalue(anprocesado);
-- Si el nomenclador y el capitulo esta cargado, completo la paractica y el subcapitulo  
UPDATE asistencial_nomenclador SET idnomenclador=t.idnomenclador,idcapitulo=t.idcapitulo,idsubcapitulo=t.idsubcapitulo,idpractica=t.idpractica
FROM (
select idasistencialnomenclador,p.idnomenclador,p.idcapitulo,p.idsubcapitulo,p.idpractica
FROM asistencial_nomenclador as an
JOIN practica as p ON p.idnomenclador = trim(an.idnomenclador)
		       and p.idcapitulo = trim(an.idcapitulo)
		       and p.idsubcapitulo = trim(substring(an.ancodigoconvenio,1,2))
		       and p.idpractica = trim(an.ancodigoconvenio)
WHERE not nullvalue(an.idnomenclador) AND not nullvalue(an.idcapitulo)
) as t 
WHERE t.idasistencialnomenclador = asistencial_nomenclador.idasistencialnomenclador
AND nullvalue(anprocesado);
--Tomo el codigo de las practicas del excel siempre que no este cargada completa la practica para siges
UPDATE asistencial_nomenclador SET idnomenclador=t.idnomenclador,idcapitulo=t.idcapitulo,idsubcapitulo=t.idsubcapitulo,idpractica=t.idpractica
FROM (
select idasistencialnomenclador,trim(an.idnomenclador) as idnomenclador,trim(an.idcapitulo) as idcapitulo,trim(substring(an.ancodigoconvenio,1,2)) as idsubcapitulo,trim(an.ancodigoconvenio) as idpractica
FROM asistencial_nomenclador as an
LEFT JOIN practica as p ON p.idnomenclador = trim(an.idnomenclador)
		       and p.idcapitulo = trim(an.idcapitulo)
		       and p.idsubcapitulo = trim(substring(an.ancodigoconvenio,1,2))
		       and p.idpractica = trim(an.ancodigoconvenio)
WHERE not nullvalue(an.idnomenclador) AND not nullvalue(an.idcapitulo) AND nullvalue(an.idpractica) AND nullvalue(p.idpractica)
) as t 
WHERE t.idasistencialnomenclador = asistencial_nomenclador.idasistencialnomenclador
AND nullvalue(anprocesado);
-- Pongo en cero la cantidad si los honorario estan en cero
UPDATE asistencial_nomenclador SET ancantidad1 = 0 WHERE anhonorario1 = 0;
UPDATE asistencial_nomenclador SET ancantidad2 = 0 WHERE anhonorario2 = 0;
UPDATE asistencial_nomenclador SET ancantidad3 = 0 WHERE anhonorario3 = 0;
UPDATE asistencial_nomenclador SET ancantgastos = 0 WHERE angastos = 0;
UPDATE asistencial_nomenclador SET ancantgastos2= 0 WHERE angastos2= 0;
UPDATE asistencial_nomenclador SET ancantgastos3= 0 WHERE angastos3= 0;
UPDATE asistencial_nomenclador SET ancantgastos4= 0 WHERE angastos4= 0;
UPDATE asistencial_nomenclador SET ancantgastos5= 0 WHERE angastos5= 0;


--Pongo en 1 la cantidad si no esta configurada pero si esta configurado el honorario
UPDATE asistencial_nomenclador SET ancantidad1 = 1 WHERE anhonorario1 <> 0 AND ancantidad1 = 0; 
UPDATE asistencial_nomenclador SET ancantidad2 = 1 WHERE anhonorario2 <> 0 AND ancantidad2 = 0;
UPDATE asistencial_nomenclador SET ancantidad3 = 1 WHERE anhonorario3 <> 0 AND ancantidad3 = 0;
UPDATE asistencial_nomenclador SET ancantgastos = 1 WHERE angastos <> 0 AND ancantgastos = 0;
UPDATE asistencial_nomenclador SET ancantgastos2= 1 WHERE angastos2<> 0 AND ancantgastos2= 0;
UPDATE asistencial_nomenclador SET ancantgastos3= 1 WHERE angastos3<> 0 AND ancantgastos3= 0;
UPDATE asistencial_nomenclador SET ancantgastos4= 1 WHERE angastos4<> 0 AND ancantgastos4= 0;
UPDATE asistencial_nomenclador SET ancantgastos5= 1 WHERE angastos5<> 0 AND ancantgastos5= 0;

resultado = 'true';
RETURN resultado;
END;
$function$
