CREATE OR REPLACE FUNCTION public.ampractconvval_configura_desagrupa(pfiltros character varying)
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
	rpracticas RECORD;
	rconveniodestino RECORD;
        rusuario RECORD; 
        rfiltros RECORD;
BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

		
SELECT INTO rconveniodestino * FROM asocconvenio  WHERE idasocconv = rfiltros.idasocconvdestino 
			AND (nullvalue(acfechafin) OR acfechafin >= current_date) LIMIT 1;
--rfiltros.practica=14.**.**.**
SELECT INTO rpracticas  SPLIT_PART(rfiltros.practica,'.',1) as idnomenclador
			,SPLIT_PART(rfiltros.practica,'.',2) as idcapitulo
			,SPLIT_PART(rfiltros.practica,'.',3) as idsubcapitulo
			,SPLIT_PART(rfiltros.practica,'.',4) as idpractica;


--Cargo la estructura necesaria para ingresar los valores que tiene configurada una asociacion a otra
--idnomenclador,idcapitulo,idsubcapitulo,idpractica,idasocconv
CREATE TEMP TABLE temppractconvval ( idpractconvval bigint,idsubcapitulo character varying,idcapitulo character varying,idpractica character varying,idnomenclador character varying,
					    idtvh1 integer default 0,
					    fijoh1 boolean default true,
					    h1 real, -- Es el que se va a usar para setear el valor fijo
					    idtvh2 integer default 0,
					    fijoh2 boolean default true,
					    h2 real default 0,
					    idtvh3 integer default 0,
					    fijoh3 boolean default true,
					    h3 real default 0,
					    idtvgs integer default 0,
					    fijogs boolean default true,
					    gasto real default 0,
					    internacion boolean default false,
                                            error character varying,
					    idasocconv bigint,
					    cantidadh1 real,
                                            iniciovigencia date,
                                            finvigencia date,
                                            pcvsis timestamp );
					

DELETE FROM temppractconvval;
--    idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,internacion,tvvigente,pcvidusuario,pcvfechainicio,pcvfechafin
--Cargo las practicas con valores con unidades
INSERT INTO temppractconvval (idpractconvval,idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica,
idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,internacion,iniciovigencia,finvigencia,pcvsis)  (
SELECT ROW_NUMBER () OVER (ORDER BY idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica) as idpractconvval
,rconveniodestino.idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica,
idtvh1,fijoh1,h1,idtvh2,fijoh2,h2,idtvh3,fijoh3,h3,idtvgs,fijogs,gasto,internacion,pcvfechainicio,pcvfechafin,now()
             FROM practconvval
	     NATURAL JOIN practica 
		WHERE practconvval.idasocconv = rfiltros.idasocconvorigen 
			AND tvvigente 
			AND idnomenclador = rpracticas.idnomenclador
			AND (idcapitulo = rpracticas.idcapitulo OR rpracticas.idcapitulo='**')
			AND (idsubcapitulo = rpracticas.idsubcapitulo OR rpracticas.idsubcapitulo='**')
			AND (idpractica = rpracticas.idpractica OR rpracticas.idpractica='**')

);
--Llamo para que se carguen los valores
SELECT INTO errores * FROM ampractconvval();

	

resultado = 'true';
RETURN resultado;
END;
$function$
