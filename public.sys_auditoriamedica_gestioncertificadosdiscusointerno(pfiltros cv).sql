CREATE OR REPLACE FUNCTION public.sys_auditoriamedica_gestioncertificadosdiscusointerno(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
     --  cvalorregistros refcursor;
     --  unvalorreg record;
        
        rfiltros RECORD;
	    elem RECORD;
		respuesta varchar;
        
     --   vfiltroid varchar;
        
      
BEGIN 
-- SELECT sys_auditoriamedica_gestioncertificadosdiscusointerno('{ nrodoc = 28272137, tipodoc = 1}');
--sys_dar_usuarioactual();
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE TEMP_ALTA_MODIFICA_CERTIFICADO_DISCAPACIDAD (  IDCERTDISCAPACIDAD INTEGER,  NRODOC VARCHAR,  TIPODOC INTEGER,   IDCENTROCERTIFICADODISCAPACIDAD INTEGER,  IDDISC INTEGER,  FECHAVTODISC DATE,  FECHAINICIODISC DATE,  NROCERTIFICADO VARCHAR,  ACOMPANANTE BOOLEAN,  PORCENTDISC SMALLINT,  ENTEMITECERT VARCHAR,  JUNTACERTIFICADORA VARCHAR,  CIF VARCHAR ) ;
CREATE TEMP TABLE TEMP_CIE10_CERTIFICADODISCAPACIDAD (  IDCIE10 INTEGER,  IDCERTDISCAPACIDAD INTEGER,   IDCENTROCIE10CERTIFICADODISCAPACIDAD INTEGER ) ;
INSERT INTO temp_alta_modifica_certificado_discapacidad  (idcertdiscapacidad,nrodoc,tipodoc,iddisc,fechavtodisc,fechainiciodisc,nrocertificado,idcentrocertificadodiscapacidad,entemitecert,porcentdisc,juntacertificadora,acompanante,cif)
VALUES (null,rfiltros.nrodoc,rfiltros.tipodoc,135,'9999-12-31','2022-09-01',NULL,1,'Sosunc',10,'Sosunc',FALSE,'Para uso Interno de Sosunc');
INSERT INTO temp_cie10_certificadodiscapacidad (idcie10,idcertdiscapacidad,idcentrocie10certificadodiscapacidad)VALUES ( 57562,NULL,NULL);
PERFORM from modificarcertificadodiscapacidad(); --->  para cargar un certificado de discapacidad
     
	 SELECT INTO elem * FROM certificadodiscapacidad WHERE iddisc = 135 AND nrodoc = rfiltros.nrodoc AND tipodoc = rfiltros.tipodoc;
	 respuesta = concat('{idcertdiscapacidad=',elem.idcertdiscapacidad,',idcentrocertificadodiscapacidad = ',elem.idcentrocertificadodiscapacidad,'}');
     return respuesta;
END;
$function$
