CREATE OR REPLACE FUNCTION public.asistencial_nomenclador_configura()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los datos de una nomenclador */
/*ampractconvval()*/
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
--Creo la tabla temporal
IF not iftableexists('tempnomencladoruno') THEN 
create temp table tempnomencladoruno 
(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos
,pmgastos2,pmcantgastos2,pmgastos3,pmcantgastos3,pmgastos4,pmcantgastos4,pmgastos5,pmcantgastos5
,descripcion,error,nrocuentac) 
as (
SELECT  an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica
,CAST(COALESCE(NULLIF(regexp_replace(anhonorario1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario1
,CAST(COALESCE(NULLIF(regexp_replace(ancantidad1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad1
,CAST(COALESCE(NULLIF(regexp_replace(anhonorario2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario2
,CAST(COALESCE(NULLIF(regexp_replace(ancantidad2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad2
,CAST(COALESCE(NULLIF(regexp_replace(anhonorario3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario3
,CAST(COALESCE(NULLIF(regexp_replace(ancantidad3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad3
,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgastos
,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos
,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgastos2
,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos2
,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgasto3
,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos3
,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgastos4
,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos4
,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgastos5
,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos5
,andescripcionpractica as descripcion
,anerror as error
,annrocuentac as nrocuentac
FROM asistencial_nomenclador as an
WHERE  nullvalue(anprocesado)  
limit 1
);
END IF;
-- Verifico si cambiaron las cantidades, o si no existe la practica para cargarla
DELETE FROM tempnomencladoruno;

--Inserto y proceso las que no existen en en nomenclador actualmente

INSERT INTO tempnomencladoruno (idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,descripcion,error,nrocuentac) 
(
SELECT DISTINCT an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica
,CAST(COALESCE(NULLIF(regexp_replace(anhonorario1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario1
,CAST(COALESCE(NULLIF(regexp_replace(ancantidad1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad1
,CAST(COALESCE(NULLIF(regexp_replace(anhonorario2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario2
,CAST(COALESCE(NULLIF(regexp_replace(ancantidad2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad2
,CAST(COALESCE(NULLIF(regexp_replace(anhonorario3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario3
,CAST(COALESCE(NULLIF(regexp_replace(ancantidad3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad3
,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgastos
,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos
,andescripcionpractica as descripcion
,concat('Se cargar desde los procesos de carga masiva') as error
,annrocuentac as nrocuentac
FROM asistencial_nomenclador as an
LEFT JOIN nomencladoruno as nu USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
LEFT JOIN practica as np USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
WHERE 

( (not nullvalue(an.idnomenclador) AND nullvalue(nu.idnomenclador) )
OR  (not nullvalue(np.idnomenclador) AND np.activo = false)
)
 AND nullvalue(anprocesado)
);

SELECT INTO resultado * FROM amnomencladoruno();
--Marco como procesadas las que termino de procesar
UPDATE asistencial_nomenclador SET anprocesado = now(),anerror = t.error
FROM tempnomencladoruno as t
 WHERE nullvalue(anprocesado) 
 AND  asistencial_nomenclador.idnomenclador = t.idnomenclador 
 AND asistencial_nomenclador.idcapitulo =t.idcapitulo 
 AND asistencial_nomenclador.idsubcapitulo = t.idsubcapitulo 
 AND asistencial_nomenclador.idpractica = t.idpractica;

--
--
--DELETE FROM tempnomencladoruno;
--
--Modifico las practicas que estan actualmente en el nomenclador, pero que cambia la descripcion
--INSERT INTO tempnomencladoruno --(idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,descripcion) 
--(
--SELECT  an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica
--,CAST(COALESCE(NULLIF(regexp_replace(anhonorario1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario1
--,CAST(COALESCE(NULLIF(regexp_replace(ancantidad1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad1
--,CAST(COALESCE(NULLIF(regexp_replace(anhonorario2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario2
--,CAST(COALESCE(NULLIF(regexp_replace(ancantidad2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad2
--,CAST(COALESCE(NULLIF(regexp_replace(anhonorario3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmhonorario3
--,CAST(COALESCE(NULLIF(regexp_replace(ancantidad3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantidad3
--,CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmgastos
--,CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric) as pmcantgastos
--,concat(andescripcionpractica, ' |(antes)| ',pdescripcion) as descripcion
--FROM asistencial_nomenclador as an
--LEFT JOIN nomencladoruno as nu USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
--LEFT JOIN practica as pr USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
--WHERE trim(andescripcionpractica) <> trim(pdescripcion)
--AND nullvalue(anprocesado)
--);

--SELECT INTO resultado * FROM amnomencladoruno();
--Marco como procesadas las que termino de procesar
--UPDATE asistencial_nomenclador SET anprocesado = now() WHERE nullvalue(anprocesado)
--AND (idnomenclador,idcapitulo,idsubcapitulo,idpractica) IN (SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica FROM tempnomencladoruno);

--
--
DELETE FROM tempnomencladoruno;
--
--Modifico las practicas que estan actualmente en el nomenclador, pero que los honorarios y las cantidades no cambian
---- Con un Group soporto el caso en el que hay mas de una vez la practica, donde todo es igual pero la descripcion es distinta
INSERT INTO tempnomencladoruno (idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,descripcion,error,nrocuentac) 
(
SELECT  an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica
,max(CAST(COALESCE(NULLIF(regexp_replace(anhonorario1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmhonorario1
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantidad1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantidad1
,max(CAST(COALESCE(NULLIF(regexp_replace(anhonorario2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmhonorario2
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantidad2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantidad2
,max(CAST(COALESCE(NULLIF(regexp_replace(anhonorario3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmhonorario3
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantidad3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantidad3
,max(CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmgastos
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantgastos
,text_concatenar(concat(andescripcionpractica,'')) as descripcion  
,text_concatenar(concat('Se cambia solo la observacion :: ',andescripcionpractica, ' |(antes)| ',pdescripcion)) as error    
,annrocuentac as nrocuentac
FROM asistencial_nomenclador as an
JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
JOIN nomencladoruno as nu USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
WHERE not nullvalue(idnomenclador) AND not nullvalue(nu.idnomenclador) and nullvalue(anprocesado) 
AND trim(andescripcionpractica) <> trim(pdescripcion)
AND ((anhonorario1::float = pmhonorario1::float )
AND (anhonorario2::float = pmhonorario2::float )
AND (anhonorario3::float = pmhonorario3::float )
AND (ancantidad1::float = pmcantidad1::float )
AND (ancantidad2::float = pmcantidad2::float )
AND (ancantidad3::float = pmcantidad3::float )
)
GROUP BY an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica,an.annrocuentac

);

SELECT INTO resultado * FROM amnomencladoruno();
--Marco como procesadas las que termino de procesar
UPDATE asistencial_nomenclador SET anprocesado = now(),anerror = t.error
FROM tempnomencladoruno as t
 WHERE nullvalue(anprocesado) 
 AND  asistencial_nomenclador.idnomenclador = t.idnomenclador 
 AND asistencial_nomenclador.idcapitulo =t.idcapitulo 
 AND asistencial_nomenclador.idsubcapitulo = t.idsubcapitulo 
 AND asistencial_nomenclador.idpractica = t.idpractica;

--
--
DELETE FROM tempnomencladoruno;
--
-- Ahora marco con un error, todas aquellas practicas que existen actualmente y que quieren cambiar canidad u honorario. 
--Esto va a permitir tener una segunda instancia de verificación. 
--27-09-2022 MaLaPi ahora se puden modificar las practicas que cambian cantidad y honorario, pero se se guarda un bk de las mismas en nuhobservacion

INSERT INTO tempnomencladoruno (idnomenclador,idcapitulo,idsubcapitulo,idpractica,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos,descripcion,error,nrocuentac) 
(
SELECT  an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica
,max(CAST(COALESCE(NULLIF(regexp_replace(anhonorario1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmhonorario1
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantidad1, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantidad1
,max(CAST(COALESCE(NULLIF(regexp_replace(anhonorario2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmhonorario2
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantidad2, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantidad2
,max(CAST(COALESCE(NULLIF(regexp_replace(anhonorario3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmhonorario3
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantidad3, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantidad3
,max(CAST(COALESCE(NULLIF(regexp_replace(angastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmgastos
,max(CAST(COALESCE(NULLIF(regexp_replace(ancantgastos, '[^-0-9.]+', '', 'g'),''),'0') AS numeric)) as pmcantgastos
,text_concatenar(andescripcionpractica||' ') as descripcion
,text_concatenar(concat('Estructura: ',anhonorario1,'<>',pmhonorario1,' Nu_h1_An ',anhonorario2,'<>',pmhonorario2,' Nu_h2_An ',anhonorario3,'<>',pmhonorario3,' Nu_h3_An ',ancantidad1,'<>',pmcantidad1,' Nu_c1_An ',ancantidad2,'<>',ancantidad2,' Nu_c2_An',ancantidad3,'<>',ancantidad3,' Nu_c3_An')) as error   
,annrocuentac as nrocuentac 
FROM asistencial_nomenclador as an
JOIN nomencladoruno as nu USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
WHERE not nullvalue(idnomenclador) AND not nullvalue(nu.idnomenclador) and nullvalue(anprocesado) 
AND ((anhonorario1::float <> pmhonorario1::float )
OR (anhonorario2::float <> pmhonorario2::float )
OR (anhonorario3::float <> pmhonorario3::float )
OR (ancantidad1::float <> pmcantidad1::float )
OR (ancantidad2::float <> pmcantidad2::float )
OR (ancantidad3::float <> pmcantidad3::float )
)
GROUP BY an.idnomenclador,an.idcapitulo,an.idsubcapitulo,an.idpractica,an.annrocuentac

);

SELECT INTO resultado * FROM amnomencladoruno();
--Marco como procesadas las que termino de procesar

UPDATE asistencial_nomenclador SET anprocesado = now(),anerror = t.error
FROM tempnomencladoruno as t
 WHERE nullvalue(anprocesado) 
 AND  asistencial_nomenclador.idnomenclador = t.idnomenclador 
 AND asistencial_nomenclador.idcapitulo =t.idcapitulo 
 AND asistencial_nomenclador.idsubcapitulo = t.idsubcapitulo 
 AND asistencial_nomenclador.idpractica = t.idpractica;

DELETE FROM tempnomencladoruno;

--DELETE FROM asistencial_nomenclador;

RETURN resultado;
END;
$function$
