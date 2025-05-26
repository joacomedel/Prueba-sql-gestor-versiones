CREATE OR REPLACE FUNCTION public.corregirprestadores_pk()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare
   rprestador record;
-- 4727

/*CREATE TABLE prestadocuitmofidicados AS (
	SELECT idprestador,pcuit,piva,idcolegio,pcategoria,idcondicioncompra,
    pnombrefantasia,pesagrupador,pdescripcion FROM  prestador where not nullvalue(pcuit) and length(pcuit)>=11 
);*/
   cprestador CURSOR FOR SELECT prestador.*,trim(REPLACE(prestador.pcuit, '-', ''))::bigint as nuevoidprestador FROM  prestador 
		JOIN prestadocuitmofidicados USING(idprestador)  
		where not nullvalue(prestador.pcuit) and length(prestador.pcuit)>=11;
--10194
--4727
/*SELECT count(*) FROM  prestador 
		JOIN prestadocuitmofidicados USING(idprestador)  
		where not nullvalue(prestador.pcuit) and length(prestador.pcuit)>=11 ;
*/
begin

 -- 10189 select count(*) from prestador 
-- 6075 select count(*) from prestador where not nullvalue(pcuit)

 OPEN cprestador;
 FETCH cprestador into rprestador;
 WHILE  found LOOP
	UPDATE prestador SET idprestador = rprestador.nuevoidprestador WHERE prestador.idprestador = rprestador.idprestador;
	UPDATE prestadocuitmofidicados SET nuevoidprestador = rprestador.nuevoidprestador WHERE prestadocuitmofidicados.idprestador = rprestador.idprestador;

	
		
	UPDATE turismoadmin SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE temporalfactura SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE tablareporteentrefechas_v2 SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE servicio SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE reintegrocomprobanteprestacion SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE reclibrofact SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE rcompcatalogo SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE prestadorgrupo SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE ordinternacion SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE pagosinstitucion SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE ordenpagoprestador SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE ordenpago_minuta SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE ordenesutilizadas  SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE informefacturacionreciprocidad  SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE informefacturacionreciprocidad_new  SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;

	UPDATE fichamedicapreauditada_fisica  SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE fichamedicaitem  SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE fichamedicainfomedrecetarioitem  SET idprestadorprescribe = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE far_preciocompra SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE far_precargarpedidocomprobante SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE far_precargarpedidocompcatalogo SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE far_pedidocanceladosporsistema SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE alcancecobertura SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	UPDATE far_ordenventareceta SET idprestador = rprestador.nuevoidprestador WHERE idprestador = rprestador.idprestador;
	
	UPDATE cliente SET nrocliente =  rprestador.nuevoidprestador  WHERE cliente.nrocliente = rprestador.idprestador  and barra=600;
	UPDATE facturaventa SET nrodoc =  rprestador.nuevoidprestador  WHERE facturaventa.nrodoc = rprestador.idprestador  and barra=600;

  
 fetch cprestador into rprestador;
 END LOOP;
 close cprestador;

 
  
return true;
end;
$function$
