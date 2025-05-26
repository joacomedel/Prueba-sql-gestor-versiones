CREATE OR REPLACE FUNCTION public.ampractconvval()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los valores de una practica en un convenio */
/*ampractconvval()*/
DECLARE
	alta refcursor; -- FOR SELECT * FROM temppractconvval WHERE nullvalue(temppractconvval.error) ORDER BY temppractconvval.idasocconv;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	resultado boolean;
	idconvenio bigint;
	verificar RECORD;
	deno_anterior bigint;
	idpracticavalor bigint;
	errores boolean;
        rusuario RECORD;
        viniciovigencia DATE;
        vsis TIMESTAMP;   
BEGIN
errores = false;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

viniciovigencia = null;
vsis = null;
IF existecolumtemp('temppractconvval', 'iniciovigencia') THEN
  
  SELECT INTO viniciovigencia iniciovigencia FROM temppractconvval WHERE nullvalue(temppractconvval.error) AND not nullvalue(iniciovigencia) LIMIT 1;
END IF;

IF existecolumtemp('temppractconvval', 'pcvsis') THEN
   SELECT INTO vsis pcvsis FROM temppractconvval WHERE nullvalue(temppractconvval.error) AND not nullvalue(pcvsis) LIMIT 1;
END IF;

--MaLaPi 04/01/2023 Elimino todas las configuraciones que ya existen en practconvval asi no se repite 
-- VAS 2024-11-15 agrego internacion
DELETE FROM temppractconvval
WHERE (idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica,internacion,iniciovigencia
,idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto
/*,idtvgs2,fijogs2,gasto2,idtvgs3,fijogs3,gasto3,
idtvgs4,fijogs4,gasto4,idtvgs5,fijogs5,idtvgs5*/
) IN (
      SELECT idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica,internacion
,pcvfechainicio
,idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto
/*,idtvgs2,fijogs2,gasto2,idtvgs3,fijogs3,gasto3,
idtvgs4,fijogs4,gasto4,idtvgs5,fijogs5,idtvgs5*/
     FROM practconvval
     NATURAL JOIN ( SELECT idasocconv::varchar,idsubcapitulo,idnomenclador,idcapitulo,idpractica,internacion
,iniciovigencia as pcvfechainicio 
,idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto
                    FROM temppractconvval 
      ) as t
WHERE tvvigente
);

-- Saco de Vigencia las configuraciones existentes
       UPDATE practconvval SET tvvigente = FALSE, pcvfechafin = viniciovigencia 
       WHERE  practconvval.tvvigente 
              AND  (idasocconv,idcapitulo,idnomenclador,idpractica,idsubcapitulo,internacion) IN (
	                  SELECT idasocconv,idcapitulo,idnomenclador,idpractica,idsubcapitulo,internacion
	                  FROM temppractconvval
	                  WHERE nullvalue(temppractconvval.error)
	                   );
	  
	--IF existecolumtemp('temppractconvval', 'cantidadh1') THEN --MaLaPi 28-08-2018 Por el momento solo se usa la columna de la cantidadh1, luego hay que verificar por todas.
        -- VAS 19-11-2024 Ya no se verifica si existe el campo en la temporal, se asume que siempre existe
		UPDATE practconvvalcantidad SET pcvcfechafin = now() 
		WHERE  nullvalue(practconvvalcantidad.pcvcfechafin) 
                       AND (idasocconv,idcapitulo,idnomenclador,idpractica,idsubcapitulo,internacion) IN (
	                         SELECT idasocconv,idcapitulo,idnomenclador,idpractica,idsubcapitulo,internacion
	                         FROM temppractconvval
	                         WHERE nullvalue(temppractconvval.error)
	              );
                                   
	--END IF;

    Select INTO idpracticavalor  * From nextval('practconvval_idpractconvval_seq');

-- VAS 22-10-2024 solo se va a tocar la configuracion de internacion o ambulatorio segun sea informado

     INSERT INTO practconvval (idpractconvval,idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica, 
                              idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,
                              internacion,tvvigente,pcvidusuario,pcvfechainicio,pcvsis,
                              idtvgasto2,fijogasto2,gasto2,
                              idtvgasto3,fijogasto3,gasto3,idtvgasto4,fijogasto4,gasto4,
                              idtvgasto5,fijogasto5,gasto5 )
     ( 	SELECT idpracticavalor as idpracticavalor,idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica
               ,idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,
               -- 221024 TRUE as internacion
               internacion  -- 221024 configuracion aplica a internacion  
               ,TRUE as tvvigente,rusuario.idusuario as pcvidusuario
               ,case when nullvalue(iniciovigencia) THEN viniciovigencia ELSE iniciovigencia END as pcvfechainicio
               ,vsis as pcvsis,idtvgs2,fijogs2,gasto2,idtvgs3,fijogs3,gasto3,                          
               idtvgs4,fijogs4,gasto4,idtvgs5,fijogs5,idtvgs5
	FROM temppractconvval
	WHERE nullvalue(temppractconvval.error)
     );
/*
    VAS 221024 Antes se generaban las 2 configuracion, a partir de ahora SOLO generamos si nos indican en la planilla
    INSERT INTO practconvval (idpractconvval,idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica, idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,
     internacion,tvvigente,pcvidusuario,pcvfechainicio,pcvsis,
                              idtvgasto2,fijogasto2,gasto2,idtvgasto3,fijogasto3,gasto3,idtvgasto4,fijogasto4,gasto4,idtvgasto5,fijogasto5,gasto5 )
    (SELECT idpracticavalor as idpracticavalor,
            idasocconv, idsubcapitulo, idnomenclador, idcapitulo, idpractica, 
            idtvh1, fijoh1, h1,
            idtvh2, fijoh2, h2,
            idtvh3, fijoh3, h3,
            idtvgs,fijogs,gasto,
            FALSE as internacion,   --- NO APLICA A INTERNACION
            TRUE as tvvigente,    
            rusuario.idusuario as pcvidusuario,
            case when nullvalue(iniciovigencia) THEN viniciovigencia ELSE iniciovigencia END as pcvfechainicio,
            vsis as pcvsis,
            idtvgs2, fijogs2, gasto2,
            idtvgs3, fijogs3, gasto3,
            idtvgs4, fijogs4, gasto4,
            idtvgs5,fijogs5,idtvgs5
	FROM temppractconvval
	WHERE nullvalue(temppractconvval.error)
     );*/
	
	--IF existecolumtemp('temppractconvval', 'cantidadh1') THEN --MaLaPi 28-08-2018 Por el momento solo se usa la columna de la cantidadh1, luego hay que verificar por todas.
         -- VAS 19-11-2024 Ya no se verifica si existe el campo en la temporal, se asume que siempre existe
		INSERT INTO practconvvalcantidad (idpractconvval,idasocconv,idsubcapitulo,idnomenclador,idcapitulo,idpractica,internacion,cantidadh1
------ VAS 20241119
,cantidadh2
,cantidadh3
,cantidadgasto
------ VAS 20241119

) 
		( SELECT  practconvval.idpractconvval,practconvval.idasocconv,practconvval.idsubcapitulo,practconvval.idnomenclador,practconvval.idcapitulo,practconvval.idpractica
		         ,practconvval.internacion,temppractconvval.cantidadh1
------ VAS 20241119
,cantidadh2
,cantidadh3
,cantidadgs
------ VAS 20241119

		   FROM practconvval 
                  -----      JOIN temppractconvval USING(idsubcapitulo,idnomenclador,idcapitulo,idpractica) --- VAS 20241119 para que tenga en cuenta internacion como parte de la clave
                   JOIN temppractconvval USING(idsubcapitulo,idnomenclador,idcapitulo,idpractica,internacion)
                   WHERE  practconvval.idpractconvval = idpracticavalor AND practconvval.idasocconv = temppractconvval.idasocconv
                 );
	--END IF;
	--VAS 221024 tratar la cantidad de las unidades aplicadas a los ayudantes y a los gastos cantidadh2 cantidadh3 y cantidadgs
        --IF existecolumtemp('temppractconvval', 'cantidadh1') THEN 
          -- VAS 19-11-2024 Ya no se verifica si existe el campo en la temporal, se asume que siempre existe
        --END IF;
  
RAISE NOTICE 'ampractconvval:: Termine de configurar  ';

resultado = 'true';
RETURN resultado;
END;$function$
