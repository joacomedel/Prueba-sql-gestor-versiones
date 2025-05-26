CREATE OR REPLACE FUNCTION public.ctacte_generar_deudas_usando_minutas(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
Genera deudas, usando minutas de pago
--SELECT * FROM ctacte_generar_deudas_usando_minutas('{idconcepto =387, nrodoc =35592957,tipodoc =1, importe =2832.99 , movconcepto=Por descuento no imputado}');
*/
DECLARE
	cpagos refcursor;
        rusuario RECORD;
	rfiltros RECORD;
        ralerta RECORD;
	vminuta varchar;
	vopc varchar;
	vpop varchar;
  

BEGIN

CREATE TEMP TABLE tempordenpago ( requiereopc boolean, idordenpagotipo integer, nrocuentachaber varchar,idvalorescaja integer,idprestador bigint,nroordenpago   bigint,fechaingreso date ,beneficiario  character varying,concepto  character varying, importetotal double precision); 
CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);
CREATE TEMP TABLE tempconsumoasi (    idconsumoasi  BIGINT, cafechamigracion TIMESTAMP, nrodoc VARCHAR(8), tipodoc INTEGER,  caimporte DOUBLE PRECISION,  signo INTEGER,  idcomprobantetipos INTEGER, caconcepto VARCHAR, idconcepto INTEGER, error BOOLEAN);
CREATE TEMP TABLE tempcomprobante (  idcomprobante bigint,  idcomprobantetipos integer,  nrocomp varchar ,  idcentrocomp INTEGER , montopagar double precision , montoretencion double precision, apagarcomprobante double precision, tipocomp varchar, observacion varchar, iddeuda bigint, idcentrodeuda integer, idpago bigint, idcentropago integer, idprestador bigint  );
CREATE TEMP TABLE tempordenpagocontable(  claveordenpagocontable VARCHAR ,  opcobservacion VARCHAR ,  idordenpagocontable BIGINT,  idcentroordenpagocontable INTEGER ,  opcmontototal  double precision  ,  opcmontoretencion  double precision  ,  opcmontocontadootra  double precision  ,  opcmontochequeprop  double precision  ,  idprestador  bigint  ,  opcfechaingreso date ,  opcmontochequetercero  double precision   );
CREATE TEMP TABLE temppagoordenpagocontable(   idvalorescaja INTEGER ,  monto  double precision  ,  observacion VARCHAR ,  tipo VARCHAR,  idcuentabancaria INTEGER,  idchequera BIGINT ,  fechacobro VARCHAR ,  fechaemision VARCHAR ,  idcheque BIGINT ,  idcentrocheque INTEGER );CREATE TEMP TABLE tretencionprestador ( 			idtiporetencion BIGINT,			idprestador BIGINT,			rpmontofijo DOUBLE PRECISION,			rpmontoporc DOUBLE PRECISION,			rpmontototal DOUBLE PRECISION,			idretencionprestador SERIAL,			rpmontobase DOUBLE PRECISION,			rpmontoretanteriores DOUBLE PRECISION);

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

SELECT INTO ralerta * 
	FROM persona, cuentacorrienteconceptotipo  
	WHERE nrodoc = trim(rfiltros.nrodoc) AND cuentacorrienteconceptotipo.idconcepto = rfiltros.idconcepto;


INSERT INTO tempordenpago (idordenpagotipo,requiereopc, nrocuentachaber,idvalorescaja,idprestador,nroordenpago,fechaingreso,beneficiario,concepto,importetotal) 
(
--VALUES(4,TRUE,'60151',0,0,null,'2018-09-12','Cuenta puenta - Siges','Pago a otros: SUBSIDIO POR FALLECIMIENTO','240.00');
SELECT 4 as idordenpagotipo,true as requiereopc, '60151' as nrocuentachaber, 0 as idvalorescaja,0 as idprestador,null as nroordenpago,current_date as fechaingreso
,concat('MP /',ralerta.nombres,' ',ralerta.apellido,' DNI:',trim(rfiltros.nrodoc)) as beneficiario,concat('MP / Generar Mov.Deuda  <',rfiltros.movconcepto,'> $',abs(rfiltros.importe),'Concepto: ',rfiltros.idconcepto,' ',ralerta.cuentacorrienteconceptotipodescrip) as concepto,abs(rfiltros.importe) as importetotal
);

INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) (
--values (  50609,50609,'120','0');
SELECT ralerta.nrocuentacontable::integer as codigo, ralerta.nrocuentacontable as nrocuentac,abs(rfiltros.importe) as debe, 0 as haber 

);

--concat(laorden ,'-',centro());
SELECT INTO vminuta * FROM generarordenpagogenerica();
DELETE FROM tempordenpago;
DELETE FROM tempordenpagoimputacion;
--UPDATE temp_devolver SET nrominuta = concat(nrominuta,'-',vminuta) WHERE id = ralerta.id;
-- La deuda El mov concepto tiene que quedar el nro de minuta
INSERT INTO tempconsumoasi(idconsumoasi,nrodoc,tipodoc,caimporte,caconcepto,idconcepto) (
--VALUES(0,'28272137',1,'120','Para devolver descuentos',387);
SELECT 0 as idconsumoasi,trim(rfiltros.nrodoc),rfiltros.tipodoc, abs(rfiltros.importe) as caimporte,concat('Generada desde MP:',vminuta,' para generar Mov. de Deuda.') as caconcepto,ralerta.idconcepto

);
PERFORM migrarconsumodesdeasiV2();
DELETE FROM tempconsumoasi;


return vminuta;
END;
$function$
