CREATE OR REPLACE FUNCTION public.sys_generar_deudas_usando_minutas()
 RETURNS void
 LANGUAGE plpgsql
AS $function$/*
Genera deudas, usando minutas de pago
*/
DECLARE
	cpagos refcursor;
        rusuario RECORD;
        ralerta RECORD;
	vminuta varchar;
	vopc varchar;
	vpop varchar;
  

BEGIN

CREATE TEMP TABLE tempordenpago ( requiereopc boolean, idordenpagotipo integer, nrocuentachaber varchar,idvalorescaja integer,idprestador bigint,nroordenpago   bigint,fechaingreso date ,beneficiario  character varying,concepto  character varying, importetotal double precision); 
CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);
CREATE TEMP TABLE tempconsumoasi (    idconsumoasi  BIGINT, cafechamigracion TIMESTAMP, nrodoc VARCHAR(8), tipodoc INTEGER,  caimporte DOUBLE PRECISION,  signo INTEGER,  idcomprobantetipos INTEGER, caconcepto VARCHAR, idconcepto INTEGER, error BOOLEAN) ;
CREATE TEMP TABLE tempcomprobante (  idcomprobante bigint,  idcomprobantetipos integer,  nrocomp varchar ,  idcentrocomp INTEGER , montopagar double precision , montoretencion double precision, apagarcomprobante double precision, tipocomp varchar, observacion varchar, iddeuda bigint, idcentrodeuda integer, idpago bigint, idcentropago integer, idprestador bigint  );
CREATE TEMP TABLE tempordenpagocontable(  claveordenpagocontable VARCHAR ,  opcobservacion VARCHAR ,  idordenpagocontable BIGINT,  idcentroordenpagocontable INTEGER ,  opcmontototal  double precision  ,  opcmontoretencion  double precision  ,  opcmontocontadootra  double precision  ,  opcmontochequeprop  double precision  ,  idprestador  bigint  ,  opcfechaingreso date ,  opcmontochequetercero  double precision   );
CREATE TEMP TABLE temppagoordenpagocontable(   idvalorescaja INTEGER ,  monto  double precision  ,  observacion VARCHAR ,  tipo VARCHAR,  idcuentabancaria INTEGER,  idchequera BIGINT ,  fechacobro VARCHAR ,  fechaemision VARCHAR ,  idcheque BIGINT ,  idcentrocheque INTEGER );CREATE TEMP TABLE tretencionprestador ( 			idtiporetencion BIGINT,			idprestador BIGINT,			rpmontofijo DOUBLE PRECISION,			rpmontoporc DOUBLE PRECISION,			rpmontototal DOUBLE PRECISION,			idretencionprestador SERIAL,			rpmontobase DOUBLE PRECISION,			rpmontoretanteriores DOUBLE PRECISION);

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
--46 personas
OPEN cpagos FOR SELECT id,nrodoc,nomape,abs(temp_devolver_2.importe) as saldo,idcomprobante,idconcepto,nrocuentac,tipodoc,nrooperacion
			FROM temp_devolver_2
                         JOIN cuentacorrientepagos USING(nrodoc,tipodoc) 
                          WHERE not nullvalue(nrooperacion) AND abs(saldo) > 1
                          AND idcomprobantetipos = 0 AND movconcepto ilike 'Descuento UNC liq 504%'
                          AND nullvalue(nrominuta)
			  AND nrodoc = '05879210'
                          ORDER BY nrodoc
                          --limit 1
                          ; 
FETCH cpagos into ralerta;
WHILE  found LOOP




INSERT INTO tempordenpago (idordenpagotipo,requiereopc, nrocuentachaber,idvalorescaja,idprestador,nroordenpago,fechaingreso,beneficiario,concepto,importetotal) 
(
--VALUES(4,TRUE,'60151',0,0,null,'2018-09-12','Cuenta puenta - Siges','Pago a otros: SUBSIDIO POR FALLECIMIENTO','240.00');
SELECT 4 as idordenpagotipo,true as requiereopc, '60151' as nrocuentachaber, 0 as idvalorescaja,0 as idprestador,null as nroordenpago,current_date as fechaingreso
,concat('MP /',ralerta.nomape,' DNI:',ralerta.nrodoc) as beneficiario,concat('MP/  imputar el Recibo <',ralerta.idcomprobante,'> $',abs(ralerta.saldo),'Concepto: ',ralerta.idconcepto) as concepto,abs(ralerta.saldo) as importetotal
);

INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) (
--values (  50609,50609,'120','0');
SELECT ralerta.nrocuentac::integer as codigo, ralerta.nrocuentac as nrocuentac,abs(ralerta.saldo) as debe, 0 as haber 

);

--concat(laorden ,'-',centro());
SELECT INTO vminuta * FROM generarordenpagogenerica();
DELETE FROM tempordenpago;
DELETE FROM tempordenpagoimputacion;
--UPDATE temp_devolver SET nrominuta = concat(nrominuta,'-',vminuta) WHERE id = ralerta.id;

-- La deuda El mov concepto tiene que quedar el nro de minuta
INSERT INTO tempconsumoasi(idconsumoasi,nrodoc,tipodoc,caimporte,caconcepto,idconcepto) (
--VALUES(0,'28272137',1,'120','Para devolver descuentos',387);
SELECT 0 as idconsumoasi,ralerta.nrodoc,ralerta.tipodoc, abs(ralerta.saldo) as caimporte,concat('Generada desde MP:',vminuta,' para resolver error de descuento.') as caconcepto,ralerta.idconcepto

);
PERFORM migrarconsumodesdeasiV2();
DELETE FROM tempconsumoasi;


-- Genero la OPC 

INSERT INTO tempcomprobante(nrocomp, idcentrocomp ,montopagar,tipocomp) (
--VALUES( NULL,NULL,'115889',1,'976.48',NULL,NULL,'OP',NULL,NULL,NULL,NULL,NULL);
SELECT split_part(vminuta, '-',1) as nrocomp,split_part(vminuta, '-',2)::integer as idcentrocomp,abs(ralerta.saldo) as montopagar,'OP' as tipocomp

);
--concat(elidordenpagocontable,'|',centro());
SELECT INTO vopc * FROM generarordenpagocontable();
vopc = replace(vopc,'|','-');

DELETE FROM tempcomprobante;

-- Genero los datos del pago

INSERT INTO tempordenpagocontable (claveordenpagocontable,opcmontototal ,opcmontoretencion  , opcmontocontadootra , opcmontochequeprop , opcmontochequetercero ,opcobservacion,opcfechaingreso) (
--VALUES( '64955-1',976.48,0,976.48,0,0,'MP: 115889-1Prestaciones Medicas - may/jun/18 - Afil. Casamiquela  Nro de Factura: ,300009262  Nro de Registro: ,142615-2018','2018-09-12');
SELECT vopc as claveordenpagocontable, abs(ralerta.saldo) as opcmontototal,0 as opcmontoretencion,abs(ralerta.saldo) as opcmontocontadootra,0 as opcmontochequeprop,0 as opcmontochequetercero,
concat('MP: ',vminuta,' Afil',ralerta.nomape,' DNI:',ralerta.nrodoc,'MP para imputar Recibo <',ralerta.idcomprobante,'> $',abs(ralerta.saldo),'Concepto: ',ralerta.idconcepto) as opcobservacion,current_date as opcfechaingreso
);
INSERT INTO temppagoordenpagocontable (idvalorescaja, monto , observacion,tipo) (
--VALUES (45, 976.48, 'Contado / OtrasCredicoop (Nqn) 24917/1', 'CT/TRANS');
SELECT 45 as idvalorescaja,abs(ralerta.saldo) as monto,'Contado / OtrasCredicoop (Nqn) 24917/1' as observacion,'CT/TRANS' as tipo
);

-- concat(elidpagoordenpagocontable,'|',centro());
SELECT INTO vpop * FROM guardarpagoordenpagocontable();

 PERFORM  cambiarestadoordenpagocontable(split_part(vopc, '-',1)::bigint,split_part(vopc, '-',2)::integer, 7, 'Generado desde SP sys_generar_deudas_usando_minutas') ;


                     UPDATE pagoordenpagocontable
                     SET popobservacion = concat(popobservacion
                                             , E'\n', '--Transferencia Manual--' ,' Fecha Pago :','06/09/2018'
                                             , ' CBU: ',   'Sin Iformacion'
                                             , ' NroOp.: ',   ralerta.nrooperacion   
                                             ,' Estado: ', 'Aceptada' ,'--Transferencia Manual-- \n' )
                     WHERE idpagoordenpagocontable = split_part(vpop, '|',1)::bigint
                            and idcentropagoordenpagocontable = split_part(vpop, '|',2)::bigint;


DELETE FROM tempordenpagocontable;
DELETE FROM temppagoordenpagocontable;

UPDATE temp_devolver SET nrominuta = concat(nrominuta,'-',vminuta),nroopc = concat(nroopc,'-',vopc),nropopc = concat(nropopc,'-',vpop) WHERE id = ralerta.id;

FETCH cpagos into ralerta;
END LOOP;
close cpagos;


END;
$function$
