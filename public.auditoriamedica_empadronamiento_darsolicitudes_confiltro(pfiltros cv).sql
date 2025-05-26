CREATE OR REPLACE FUNCTION public.auditoriamedica_empadronamiento_darsolicitudes_confiltro(pfiltros character varying)
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
        vfechadesde DATE;
        vfechahasta DATE;
      
BEGIN 
--SELECT * FROM auditoriamedica_empadronamiento_darsolicitudes_confiltro('{ nrodoc=*, fechadesde=2022-09-28,fechahasta=2025-09-28}');
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    vfechadesde = CURRENT_DATE - 7::integer;
    vfechahasta = CURRENT_DATE + 1::integer;
    IF pfiltros ilike '%fechadesde=%' THEN
      vfechadesde = rfiltros.fechadesde;
    END IF;
     
    IF pfiltros ilike '%fechahasta=%' THEN
      vfechahasta = rfiltros.fechahasta +1::integer;
    END IF;    

     CREATE TEMP TABLE temp_solicitudauditoria_confiltros AS (
	select idmonodroga,idfichamedicainfomedicamento,saidosisdiaria,idsolicitudauditoriaitem_ext,safechaingreso,monnombre,sadiagnostico,p.nrodoc,p.nombres,p.apellido,CONCAT(usu.nombre,usu.apellido) as cargadopor,saeobservacion
		FROM 
		 solicitudauditoria as afi 
		 NATURAL JOIN solicitudauditoriaitem 
		 NATURAL JOIN solicitudauditoriaitem_ext  
		 NATURAL JOIN monodroga 
		 NATURAL JOIN solicitudauditoriaestado 
		 JOIN usuario as usu ON(saeidusuario = idusuario) 
		 JOIN persona AS p ON(p.nrodoc =afi.nrodoc and p.tipodoc = afi.tipodoc)
		WHERE nullvalue(saefechafin) 
                AND ( rfiltros.nrodoc = '*' OR p.nrodoc = rfiltros.nrodoc )
                AND ( safechaingreso >= vfechadesde )
                AND ( safechaingreso <= vfechahasta )
		 		AND saipraxys IS null
       ORDER BY safechaingreso DESC
     );

     
     return 'Listo';
END;
$function$
