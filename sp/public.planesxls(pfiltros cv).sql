CREATE OR REPLACE FUNCTION public.planesxls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;

    --GK 18/04/2022 : Creado para reporte excel historial planes tarjeta
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
    
       CREATE TEMP TABLE temp_planesxls
   AS (
       SELECT * 
       --,'1-ID PLAN#idplantarjeta@2-Tipo Tarjeta#descripcion@3-CUOTAS#ptcuotas@4-USUARIO CARGA#login@5-Fec. Inicio#ptfechadesde@6-Fec. Fin#ptfechahasta@7-POSNET#ptposnet@8-Fec. Modif.#ptfechamodif'::text as mapeocampocolumna
       -- BelenA 03/09/24. Agrego el factor financiero y el arancel a pedido de Andrea. También descomento en el where la fecha para que lo use ella para filtrar
       ,'1-ID PLAN#idplantarjeta@2-Tipo Tarjeta#descripcion@3-CUOTAS#ptcuotas@4-Factor Financiero#ptfactorfinanciero@5-Arancel#ptarancel@6-USUARIO CARGA#login@7-Fec. Inicio#ptfechadesde@8-Fec. Fin#ptfechahasta@9-POSNET#ptposnet@10-Fec. Modif.#ptfechamodif'::text as mapeocampocolumna
       FROM planes_tarjeta 
       LEFT JOIN valorescaja USING(idvalorescaja)
       LEFT JOIN usuario ON (idusuario=ptidusuario)
       WHERE ptfechadesde >= rfiltros.fechadesde AND rfiltros.fechahasta >= ptfechahasta
       ORDER BY idplantarjeta desc,ptfechamodif );
     
  
return true;
END;
$function$
