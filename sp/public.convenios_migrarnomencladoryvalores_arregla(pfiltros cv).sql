CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_arregla(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
        
        rfiltros RECORD;
        
        vfiltroid varchar;
        
      
BEGIN 
-- SELECT convenios_migrarnomencladoryvalores_confiltro('{ accion = desactivar}');
--sys_dar_usuarioactual();

--VAS 22-10-24 parainternacion es null o blanquito, es decir tiene la configuracion por defecto
-- configuracion por defecto si es null o blanquito, entonces la configuracion aplica SOLO ambulatorio 
-- Para que afecte a internacion se debe poner en la celda 'si'

-- aplicanomenclador por defecto se toma la configuracion de las cantidades de unidades del nomenclador, si no se desea esta configuracion se debe indicar explicitamente con NO

--MaLaPi 26-07-2024 cambio los valores NULL por blanquito donde los requiere el sistema
UPDATE nomenclador_para_migrar 
SET hon = sys_dar_valorsinull(hon,''),
    ayud_1 = sys_dar_valorsinull(ayud_1,''),
    ayud_2 = sys_dar_valorsinull(ayud_2,''),
    gastos = sys_dar_valorsinull(gastos,''),
    incorpora = sys_dar_valorsinull(incorpora,''),
    tipounidaday1 = sys_dar_valorsinull(tipounidaday1,''),
    valordeunidaday1= sys_dar_valorsinull(valordeunidaday1,''),

--VAS 22-10-24 tipounidaday2
   parainternacion = CASE WHEN (UPPER(trim(parainternacion))='SI') THEN 'SI'
                     ELSE   sys_dar_valorsinull(parainternacion,'NO') END,
    

   aplicanomenclador = CASE WHEN (UPPER(trim(aplicanomenclador))='NO') THEN 'NO'
                     ELSE 
                      -- sys_dar_valorsinull(aplicanomenclador,'SI') END,
                        case  WHEN (UPPER(trim(aplicanomenclador))='SI') THEN 'SI'
                        else   'SI' END END,

   tipounidaday2 = sys_dar_valorsinull(tipounidaday2,''),
   valordeunidaday2 = sys_dar_valorsinull(valordeunidaday2,''),

--VAS 22-10-24 tipounidaday2
   tipounidadgs = sys_dar_valorsinull(tipounidadgs,''),
   valordeunidadgs = sys_dar_valorsinull(valordeunidadgs,''),
   asociaciones_sigesgastos = sys_dar_valorsinull(asociaciones_sigesgastos,'') 
   WHERE nullvalue(fechaproceso);

   UPDATE nomenclador_para_migrar SET activo = 'Si'
   where trim(activo) = '' AND (nullvalue(fechaproceso) OR nullvalue(npmfechacargavalorfijo));

--actualiza el valor del campo parainternacion
UPDATE nomenclador_para_migrar SET parainternacion = parainternacion   where nullvalue(nomenclador_para_migrar.parainternacion);

-- Asumo que si la practica tiene valor cero en honorario y ademas esta marcada como aciva debe estar configurada para la asociacion, entonces el valor no puede quedar en cero

UPDATE nomenclador_para_migrar SET hon = '0.01' where sys_dar_numero(hon,0.01) = 0 AND activo ilike 'Si' AND nullvalue(fechaproceso);

--Quita los espacios de asociaciones_siges VAS 040724
UPDATE nomenclador_para_migrar SET asociaciones_siges = trim(asociaciones_siges) where nullvalue(fechaproceso);

UPDATE nomenclador_mapea_asociacion_para_migrar SET asociaciones_siges = trim(asociaciones_siges) 
WHERE nullvalue(nmafechaproceso) ;  

UPDATE nomenclador_tipounidad_para_migrar SET asociaciones_siges = trim(asociaciones_siges) 
WHERE nullvalue(ntupmfechaproceso);

UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = trim(asociaciones_siges) 
WHERE nullvalue(nvfpmfechaproceso);

---nomenclador_valorfijo_para_migrar

--La asociacion de Uso Interno es la 155 - Para uso Interno

UPDATE nomenclador_para_migrar SET asociaciones_siges = '155' where asociaciones_siges ilike '%interno%' AND nullvalue(fechaproceso);

--Agrego los elementos donde codigocorto le falta un cero a la izquierda

UPDATE nomenclador_mapea_asociacion_para_migrar SET codigocorto = trim(lpad(codigocorto, 6, '0'))
where length(codigocorto) = 5; 

UPDATE nomenclador_para_migrar SET codigocorto = trim(lpad(codigocorto, 6, '0'))
where length(codigocorto) = 5;

----nomenclador_valorfijo_para_migrar

--nomenclador_valorfijo_para_migrar::Agrego los elementos donde codigocorto le falta un cero a la izquierda

UPDATE nomenclador_valorfijo_para_migrar SET codigocorto = trim(lpad(codigocorto, 6, '0'))
where length(codigocorto) = 5; 

UPDATE nomenclador_valorfijo_para_migrar SET idnomenclador = trim(replace(idnomenclador,'.',''))
where nullvalue(nvfpmfechaproceso); 

--Acomodo el capitulo, subcapitulo y practica cuando se usa el codigo corto
UPDATE nomenclador_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
FROM  (
select trim(split_part(codigocorto,'.',1)) as idcapitulocc,trim(split_part(codigocorto,'.',2)) as idsubcapitulocc,trim(split_part(codigocorto,'.',3)) as idpracticacc,idnomencladorparamigrar  
   from nomenclador_para_migrar 
   WHERE nullvalue(fechaproceso) AND nullvalue(errordecarga) 
     AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) <> ''
) as t
WHERE  nomenclador_para_migrar.idnomencladorparamigrar = t.idnomencladorparamigrar
AND nullvalue(fechaproceso) AND nullvalue(errordecarga) 
AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) <> '';

--nomenclador_valorfijo_para_migrar::Acomodo el capitulo, subcapitulo y practica cuando se usa el codigo corto

UPDATE nomenclador_valorfijo_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
FROM  (
select trim(split_part(codigocorto,'.',1)) as idcapitulocc,trim(split_part(codigocorto,'.',2)) as idsubcapitulocc,trim(split_part(codigocorto,'.',3)) as idpracticacc,idnomencladorvalorfijoparamigrar  
   from nomenclador_valorfijo_para_migrar 
   WHERE nullvalue(nvfpmfechaproceso) AND nullvalue(nvfpmerrordecarga) 
     AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) <> ''
) as t
WHERE  nomenclador_valorfijo_para_migrar.idnomencladorvalorfijoparamigrar = t.idnomencladorvalorfijoparamigrar
AND nullvalue(nvfpmfechaproceso) AND nullvalue(nvfpmerrordecarga) 
AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) <> '';
	 
-- Cuando el codigo corto no se separa por . sino que es de longitud 6

UPDATE nomenclador_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
FROM  (
select trim(substring(codigocorto,1,2)) as idcapitulocc,trim(substring(codigocorto,3,2)) as idsubcapitulocc,trim(substring(codigocorto,5,2)) as idpracticacc,idnomencladorparamigrar  
   from nomenclador_para_migrar 
   WHERE nullvalue(fechaproceso) AND nullvalue(errordecarga) 
     AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6
) as t
WHERE  nomenclador_para_migrar.idnomencladorparamigrar = t.idnomencladorparamigrar
AND nullvalue(fechaproceso) AND nullvalue(errordecarga) 
AND codigocorto <> ''
      AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6;

-- nomenclador_valorfijo_para_migrar:: Cuando el codigo corto no se separa por . sino que es de longitud 6

UPDATE nomenclador_valorfijo_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
FROM  (
select trim(substring(codigocorto,1,2)) as idcapitulocc,trim(substring(codigocorto,3,2)) as idsubcapitulocc,trim(substring(codigocorto,5,2)) as idpracticacc,idnomencladorvalorfijoparamigrar  
   from nomenclador_valorfijo_para_migrar 
   WHERE nullvalue(nvfpmfechaproceso) AND nullvalue(nvfpmerrordecarga) 
     AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6
) as t
WHERE  nomenclador_valorfijo_para_migrar.idnomencladorvalorfijoparamigrar = t.idnomencladorvalorfijoparamigrar
AND nullvalue(nvfpmfechaproceso) AND nullvalue(nvfpmerrordecarga) 
AND codigocorto <> ''
      AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6;

UPDATE nomenclador_modifica_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
FROM  (
select trim(substring(codigocorto,1,2)) as idcapitulocc,trim(substring(codigocorto,3,2)) as idsubcapitulocc,trim(substring(codigocorto,5,2)) as idpracticacc,idnomencladormodifica  
   from nomenclador_modifica_para_migrar 
   WHERE nullvalue(fechaproceso) AND nullvalue(errordecarga) 
     AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6
) as t
WHERE  nomenclador_modifica_para_migrar.idnomencladormodifica = t.idnomencladormodifica
AND nullvalue(fechaproceso) AND nullvalue(errordecarga) 
AND codigocorto <> ''
      AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6;

--Elimino las filas que no tienen cargado el valor del honorario

DELETE FROM nomenclador_valorfijo_para_migrar WHERE nullvalue(hon) AND nullvalue(nvfpmfechaproceso);

	 

--Acomodo el capitulo, subcapitulo y practica cuando se usa el codigo corto
	 
UPDATE nomenclador_mapea_asociacion_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
,idcapitulogasto = t.idcapitulocc,idsubcapitulogasto = t.idsubcapitulocc,idpracticagasto = t.idpracticacc
FROM  (
select trim(split_part(codigocorto,'.',1)) as idcapitulocc,trim(split_part(codigocorto,'.',2)) as idsubcapitulocc,trim(split_part(codigocorto,'.',3)) as idpracticacc,idnomencladormapeaasociacion  
   from nomenclador_mapea_asociacion_para_migrar 
   WHERE nullvalue(nmafechaproceso) AND nullvalue(nmaerrordecarga) 
     AND codigocorto <> ''
    AND trim(split_part(codigocorto,'.',2)) <> ''
     
) as t
WHERE  nomenclador_mapea_asociacion_para_migrar.idnomencladormapeaasociacion = t.idnomencladormapeaasociacion
AND nullvalue(nmafechaproceso) AND nullvalue(nmaerrordecarga) 
AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) <> '';
	 
	 
-- Cuando el codigo corto no se separa por . sino que es de longitud 6

UPDATE nomenclador_mapea_asociacion_para_migrar SET idcapitulo = t.idcapitulocc,idsubcapitulo = t.idsubcapitulocc,idpractica = t.idpracticacc
,idcapitulogasto = t.idcapitulocc,idsubcapitulogasto = t.idsubcapitulocc,idpracticagasto = t.idpracticacc
FROM  (
select trim(substring(codigocorto,1,2)) as idcapitulocc,trim(substring(codigocorto,3,2)) as idsubcapitulocc,trim(substring(codigocorto,5,2)) as idpracticacc,idnomencladormapeaasociacion  
   from nomenclador_mapea_asociacion_para_migrar 
   WHERE nullvalue(nmafechaproceso) AND nullvalue(nmaerrordecarga) 
     AND codigocorto <> ''
     AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6
) as t
WHERE  nomenclador_mapea_asociacion_para_migrar.idnomencladormapeaasociacion = t.idnomencladormapeaasociacion
AND nullvalue(nmafechaproceso) AND nullvalue(nmaerrordecarga) 
AND codigocorto <> ''
      AND trim(split_part(codigocorto,'.',2)) = ''
     AND length(codigocorto) = 6;
 
 -- Vinculo las tablas de migracion
 UPDATE nomenclador_mapea_asociacion_para_migrar SET idnomencladorparamigrar = t.idnomencladorparamigrar
FROM  (
select idnomenclador,idcapitulo,idsubcapitulo,idpractica,max(idnomencladorparamigrar) as idnomencladorparamigrar
   from nomenclador_para_migrar 
   GROUP BY   idnomenclador,idcapitulo,idsubcapitulo,idpractica
   
) as t
WHERE  nomenclador_mapea_asociacion_para_migrar.idnomenclador = t.idnomenclador  
AND nomenclador_mapea_asociacion_para_migrar.idcapitulo = t.idcapitulo 
AND nomenclador_mapea_asociacion_para_migrar.idsubcapitulo = t.idsubcapitulo 
AND nomenclador_mapea_asociacion_para_migrar.idpractica = t.idpractica
AND nullvalue(nmafechaproceso) AND nullvalue(nmaerrordecarga) 
AND nullvalue(nomenclador_mapea_asociacion_para_migrar.idnomencladorparamigrar); 

-- Para que quede vinculado la seccion de Gastos
 UPDATE nomenclador_mapea_asociacion_para_migrar SET idnomencladorparamigrargasto = t.idnomencladorparamigrargasto
FROM  (
select idnomenclador as idnomencladorgasto,idcapitulo as idcapitulogasto,idsubcapitulo as idsubcapitulogasto,idpractica as idpracticagasto,max(idnomencladorparamigrar) as idnomencladorparamigrargasto
   from nomenclador_para_migrar 
   GROUP BY   idnomenclador,idcapitulo,idsubcapitulo,idpractica
) as t 
--USING(idnomencladorgasto,idcapitulogasto,idsubcapitulogasto,idpracticagasto)
WHERE  nomenclador_mapea_asociacion_para_migrar.idnomencladorgasto = t.idnomencladorgasto  
AND nomenclador_mapea_asociacion_para_migrar.idcapitulogasto = t.idcapitulogasto 
AND nomenclador_mapea_asociacion_para_migrar.idsubcapitulogasto = t.idsubcapitulogasto 
AND nomenclador_mapea_asociacion_para_migrar.idpracticagasto = t.idpracticagasto
--AND nullvalue(nmafechaproceso) AND nullvalue(nmaerrordecarga) 
AND nullvalue(nmafechaprocesogasto)
AND nullvalue(nomenclador_mapea_asociacion_para_migrar.idnomencladorparamigrargasto);

-- Modifico el Separador de las Asociaciones.
 UPDATE nomenclador_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'/','@');
 UPDATE nomenclador_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'-','@');

-- Modifico el Separador de las Asociaciones.
 
 UPDATE nomenclador_mapea_asociacion_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'/','@');
 UPDATE nomenclador_mapea_asociacion_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'-','@');

-- Modifico el Separador de las Asociaciones en las unidades.
 UPDATE nomenclador_tipounidad_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'/','@');
 UPDATE nomenclador_tipounidad_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'-','@');

-- Modifico el Separador de las Asociaciones en las unidades.
 UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'/','@');
 UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'-','@');

--Arreglo una asociacion que esta mal generada en los excel
UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'@ 10001 @','@ 1001 @')  WHERE asociaciones_siges ilike '%10001%';

--Modifico la descripcion de las practicas configuadas y sin procesar

UPDATE nomenclador_modifica_para_migrar SET pdescripcionanterior  = t.pdescripcion FROM
(
select pdescripcion,idnomencladormodifica
idpracticacc,idnomencladormodifica  
   from nomenclador_modifica_para_migrar 
   NATURAL JOIN practica
   WHERE nullvalue(fechaproceso) AND nullvalue(errordecarga) 
    AND activo
) as t
WHERE nomenclador_modifica_para_migrar.idnomencladormodifica = t.idnomencladormodifica
AND nullvalue(fechaproceso) 
AND nullvalue(errordecarga);

UPDATE practica SET pdescripcion  = t.pdescripcionnueva
FROM  (
select pdescripcionnueva,idnomencladormodifica,idnomenclador,idcapitulo,idsubcapitulo,idpractica
   from nomenclador_modifica_para_migrar 
   WHERE nullvalue(fechaproceso) 
     AND not nullvalue(pdescripcionanterior)
    
) as t
WHERE  practica.idnomenclador = t.idnomenclador AND practica.idcapitulo = t.idcapitulo 
AND practica.idsubcapitulo = t.idsubcapitulo AND practica.idpractica = t.idpractica
AND activo;

UPDATE nomenclador_modifica_para_migrar SET fechaproceso  = now()
WHERE  nullvalue(fechaproceso)  
AND nullvalue(errordecarga) AND not nullvalue(pdescripcionanterior);

--Modifico el Rango de Asociaciones

UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'@ 1023 AL 1070','@ 1023 @ 1024 @ 1025 @ 1026 @ 1027 @ 1028 @ 1029 @ 1030 @ 1031 @ 1032 @ 1033 @ 1034 @ 1035 @ 1035 @ 1036 @ 1037 @ 1038 @ 1039 @ 1040 @ 1041 @ 1042 @ 1043 @ 1044 @ 1045 @ 1046 @ 1047 @ 1048 @ 1049 @ 1050 @ 1051 @ 1052 @ 1053 @ 1054 @ 1055 @ 1056 @ 1057 @ 1058 @ 1059 @ 1060 @ 1061 @ 1062 @ 1063 @ 1064 @ 1065 @ 1066 @ 1067 @ 1068 @ 1069 @ 1070') WHERE asociaciones_siges ilike '%1023 AL 1070%' AND  nullvalue(nvfpmfechaproceso);

UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = replace(asociaciones_siges,'@1023 AL 1070','@ 1023 @ 1024 @ 1025 @ 1026 @ 1027 @ 1028 @ 1029 @ 1030 @ 1031 @ 1032 @ 1033 @ 1034 @ 1035 @ 1035 @ 1036 @ 1037 @ 1038 @ 1039 @ 1040 @ 1041 @ 1042 @ 1043 @ 1044 @ 1045 @ 1046 @ 1047 @ 1048 @ 1049 @ 1050 @ 1051 @ 1052 @ 1053 @ 1054 @ 1055 @ 1056 @ 1057 @ 1058 @ 1059 @ 1060 @ 1061 @ 1062 @ 1063 @ 1064 @ 1065 @ 1066 @ 1067 @ 1068 @ 1069 @ 1070') WHERE asociaciones_siges ilike '%1023 AL 1070%' AND  nullvalue(nvfpmfechaproceso);

--Para sacar el @ cuando queda al final, sin datos
UPDATE nomenclador_para_migrar SET asociaciones_siges = substring(asociaciones_siges from '(.*)@') WHERE asociaciones_siges ilike '%@';
UPDATE nomenclador_mapea_asociacion_para_migrar SET asociaciones_siges = substring(asociaciones_siges from '(.*)@') WHERE asociaciones_siges ilike '%@';
UPDATE nomenclador_tipounidad_para_migrar SET asociaciones_siges = substring(asociaciones_siges from '(.*)@') WHERE asociaciones_siges ilike '%@';
UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = substring(asociaciones_siges from '(.*)@') WHERE asociaciones_siges ilike '%@';

--Arreglo las asociones en la tabla que migra los valores fijos, pues la suelen cargar en solo 1 renglon del excel
UPDATE nomenclador_valorfijo_para_migrar SET asociaciones_siges = asociaciones_sigesdef
FROM (
select asociaciones_siges as asociaciones_sigesdef,nvfpmhoja_excel,nvfpmfechaingreso 
from nomenclador_valorfijo_para_migrar 
where 
  nullvalue(nvfpmfechaproceso) 
AND not nullvalue(nvfpmhoja_excel)
AND not nullvalue(asociaciones_siges)
GROUP BY asociaciones_siges,nvfpmhoja_excel,nvfpmfechaingreso
) as asoc
WHERE nullvalue(nomenclador_valorfijo_para_migrar.asociaciones_siges) 
AND nomenclador_valorfijo_para_migrar.nvfpmhoja_excel = asoc.nvfpmhoja_excel
AND nomenclador_valorfijo_para_migrar.nvfpmfechaingreso = asoc.nvfpmfechaingreso
AND  nullvalue(nomenclador_valorfijo_para_migrar.nvfpmfechaproceso) ;

 

     
     return 'Listo';
END;
$function$
