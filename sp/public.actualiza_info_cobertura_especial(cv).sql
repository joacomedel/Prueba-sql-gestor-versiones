CREATE OR REPLACE FUNCTION public.actualiza_info_cobertura_especial(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	rfiltros record; 
	rsolicitudauditoria record;
        

BEGIN
 	/*select  * from actualiza_info_cobertura_especial('{nrodoc=27091730}');*/
 	EXECUTE sys_dar_filtros($1) INTO rfiltros;
	
	
	-- 1 BUSCO LA SOLICITUD DE AUDITORIA
	SELECT INTO rsolicitudauditoria  CASE WHEN (saicobertura<1 ) THEN round((saicobertura*100)::numeric,2) ELSE saicobertura END ,   solicitudauditoriaitem.*
	FROM solicitudauditoriaitem 
	NATURAL JOIN solicitudauditoria
	NATURAL JOIN solicitudauditoriaitem_ext
	where saicobertura <= 1 
         AND  nrodoc=rfiltros.nrodoc  ;
	
    --- 2 Actualizao la solicitudauditoriaitem
	UPDATE solicitudauditoriaitem SET saicobertura = CASE WHEN (saicobertura<1 ) THEN round((saicobertura*100)::numeric,2) ELSE saicobertura END
	WHERE idsolicitudauditoria=rsolicitudauditoria.idsolicitudauditoria AND idcentrosolicitudauditoria=rsolicitudauditoria.idcentrosolicitudauditoria;
	
	--- 3 Actualizao la solicitudauditoriaitem
	UPDATE fichamedicainfomedicamento SET fmimcobertura = CASE WHEN (fmimcobertura<0.01 ) THEN round((fmimcobertura*100)::numeric,2) ELSE fmimcobertura END
    WHERE (idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento) IN(
           SELECT idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento
           FROM solicitudauditoriaitem
           WHERE idsolicitudauditoria=rsolicitudauditoria.idsolicitudauditoria AND idcentrosolicitudauditoria=rsolicitudauditoria.idcentrosolicitudauditoria
	
	); 
	
	--- 3 Actualizao la solicitudauditoriaitem_ext
	UPDATE solicitudauditoriaitem_ext SET saipraxys = null
	WHERE (idsolicitudauditoriaitem,	idcentrosolicitudauditoriaitem) IN (
               SELECT idsolicitudauditoriaitem,	idcentrosolicitudauditoriaitem
               FROM solicitudauditoriaitem 
               WHERE  idsolicitudauditoria=rsolicitudauditoria.idsolicitudauditoria 
		              AND idcentrosolicitudauditoria=rsolicitudauditoria.idcentrosolicitudauditoria

	);

	return true;
END;$function$
