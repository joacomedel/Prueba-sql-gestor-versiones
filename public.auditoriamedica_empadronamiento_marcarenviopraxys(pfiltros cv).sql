CREATE OR REPLACE FUNCTION public.auditoriamedica_empadronamiento_marcarenviopraxys(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       cvalormedicamento refcursor;
       unvalormed record;
       unvalormedanterior record;
       primero boolean;
        
        rfiltros RECORD;
        rusuario RECORD;
        vfiltroid varchar;
        idsolitem_ext INTEGER;
      
BEGIN 
--SELECT * FROM auditoriamedica_empadronamiento_darsolicitudes_confiltro('{ nrodoc=*, fechadesde=2022-09-28,fechahasta=2025-09-28}');
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 	idsolitem_ext = rfiltros.idsolicitudauditoriaitem_ext;

	UPDATE solicitudauditoriaitem_ext
	SET saipraxys = CURRENT_TIMESTAMP
	WHERE idsolicitudauditoriaitem_ext = idsolitem_ext;
     
     return 'Listo';
END;
$function$
