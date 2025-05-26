CREATE OR REPLACE FUNCTION public.sys_auditar_suap_previo(pparametros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$  DECLARE

       ccursor refcursor;
       ccursororden refcursor;
      
        
        rfiltros RECORD;
        rusuario RECORD;
        elem RECORD;
	elemorden  RECORD;
        rprestador RECORD;
	rvalores RECORD;
        rverifica RECORD;
        rfacturapractica RECORD;
        rverificadebito RECORD;
	rverificaconf RECORD;
        rverificaestado RECORD;
        rcontrolcoseguro RECORD;
        rctagastodebito RECORD;
        rverificacoseguro RECORD;
        rcosegurodescontado RECORD;
        rcosegurofichamedicapreauditada  RECORD;

        vcategoria VARCHAR; 
        vbandera VARCHAR;
	vimporte double precision;
        vimportecoseguro double precision;
	vimportefacturadomenoscoseguro double precision;
	vimportecosegurofalta double precision;
	vimportesincoseguro boolean;
	
        vcantidad INTEGER;

  BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

     EXECUTE sys_dar_filtros(pparametros) INTO rfiltros;

--MaLaPi 19/11/2020 Coloco en cero todos los NroRecibo que nos son validos
UPDATE suap_colegio_medico   SET recibo_siges = 0 where not textregexeq(trim(recibo_siges ),'^[[:digit:]]+(\.[[:digit:]]+)?$');


--10-12-2019 Malapi Normalizo el Nro de Recibo, el cuit del prestador y el codigo de las practicas
UPDATE suap_colegio_medico SET idrecibo = t.idrecibo, centro = t.centro FROM (
 SELECT SUBSTRING(recibo_siges,1,LENGTH(recibo_siges)-4)::bigint as idrecibo,SUBSTRING(recibo_siges,LENGTH(recibo_siges)-3,LENGTH(recibo_siges))::bigint as centro,recibo_siges,idsuapcolegiomedico 
 FROM suap_colegio_medico
 WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio
 AND LENGTH(recibo_siges) > 9 AND recibo_siges not ilike 'A%'
 ) as t
WHERE suap_colegio_medico.idsuapcolegiomedico = t.idsuapcolegiomedico
AND nullvalue(suap_colegio_medico.idrecibo);

--27/05/2020 MaLaPi aveces el idrecibo lo mandan sin el centro, por lo que asumo que siempre es 1
--16/06/2022 MaLaPi ahora solo queda 1 cero luego del Idrecibo por lo que hay que soportar las 2 versiones... lo voy a hacer verificando primero que exista un recibo valido
--UPDATE suap_colegio_medico SET idrecibo = t.idrecibo, centro = t.centro FROM (
-- SELECT SUBSTRING(recibo_siges,1,LENGTH(recibo_siges)-2)::bigint as idrecibo,1 as centro,recibo_siges,idsuapcolegiomedico 
-- FROM suap_colegio_medico
-- WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio
--AND LENGTH(suap_colegio_medico.recibo_siges) < 9
-- AND LENGTH(recibo_siges) < 9 AND recibo_siges not ilike 'A%'
-- ) as t
--WHERE suap_colegio_medico.idsuapcolegiomedico = t.idsuapcolegiomedico
--AND nullvalue(suap_colegio_medico.idrecibo)
--AND LENGTH(suap_colegio_medico.recibo_siges) > 2
--AND LENGTH(suap_colegio_medico.recibo_siges) < 9;

--MaLaPi 16-06-2022 cuando hay que quitar 2 ceros
UPDATE suap_colegio_medico SET idrecibo = t.idrecibo, centro = t.centro FROM (
 SELECT SUBSTRING(recibo_siges,1,LENGTH(recibo_siges)-2)::bigint as idrecibo,1 as centro,recibo_siges,idsuapcolegiomedico 
 FROM suap_colegio_medico
 WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio
 AND nullvalue(suap_colegio_medico.idrecibo)
 AND LENGTH(recibo_siges) < 9 AND recibo_siges not ilike 'A%'
 AND  SUBSTRING(recibo_siges,1,LENGTH(recibo_siges)-2)::bigint IN (
  SELECT idrecibo FROM ordenrecibo NATURAL JOIN orden WHERE tipo = 56 AND centro = 1 )
  ) as t
WHERE suap_colegio_medico.idsuapcolegiomedico = t.idsuapcolegiomedico
AND nullvalue(suap_colegio_medico.idrecibo)
AND LENGTH(suap_colegio_medico.recibo_siges) > 2
AND LENGTH(suap_colegio_medico.recibo_siges) < 9
AND nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio
AND nullvalue(scmprocesado);


--MaLaPi 16-06-2022 cuando hay que quitar 1 ceros
UPDATE suap_colegio_medico SET idrecibo = t.idrecibo, centro = t.centro FROM (
  SELECT SUBSTRING(recibo_siges,1,LENGTH(recibo_siges)-1)::bigint as idrecibo,1 as centro,recibo_siges,idsuapcolegiomedico 
 FROM suap_colegio_medico
 WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio
 AND nullvalue(suap_colegio_medico.idrecibo)
 AND LENGTH(recibo_siges) < 9 AND recibo_siges not ilike 'A%'
 AND  SUBSTRING(recibo_siges,1,LENGTH(recibo_siges)-1)::bigint IN (
  SELECT idrecibo FROM ordenrecibo NATURAL JOIN orden WHERE tipo = 56 AND centro = 1 )
  ) as t
WHERE suap_colegio_medico.idsuapcolegiomedico = t.idsuapcolegiomedico
AND nullvalue(suap_colegio_medico.idrecibo)
AND LENGTH(suap_colegio_medico.recibo_siges) > 2
AND LENGTH(suap_colegio_medico.recibo_siges) < 9
AND nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio
AND nullvalue(scmprocesado);


UPDATE suap_colegio_medico SET cuit_efector = trim(replace(cuit_efector,'-','')) WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio;



--Arreglo el codigo de las practicas, aveces le ponen un punto
update suap_colegio_medico SET codigo_practica = trim(replace(codigo_practica,'.','')) WHERE nroregistro=rfiltros.nroregistro AND anio = rfiltros.anio  AND nullvalue(scmprocesado); 



   RETURN 'true';
  END;
$function$
