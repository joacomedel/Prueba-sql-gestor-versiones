CREATE OR REPLACE FUNCTION public.sys_generar_deudas_usando_recibos(bigint, integer)
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

CREATE TEMP TABLE tempordenpago ( idordenpagotipo integer, nrocuentachaber varchar,idvalorescaja integer,idprestador bigint,nroordenpago   bigint,fechaingreso date ,beneficiario  character varying,concepto  character varying, importetotal double precision); 
CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);
CREATE TEMP TABLE tempconsumoasi (    idconsumoasi  BIGINT, cafechamigracion TIMESTAMP, nrodoc VARCHAR(8), tipodoc INTEGER,  caimporte DOUBLE PRECISION,  signo INTEGER,  idcomprobantetipos INTEGER, caconcepto VARCHAR, idconcepto INTEGER, error BOOLEAN) ;
CREATE TEMP TABLE tempcomprobante (  idcomprobante bigint,  idcomprobantetipos integer,  nrocomp varchar ,  idcentrocomp INTEGER , montopagar double precision , montoretencion double precision, apagarcomprobante double precision, tipocomp varchar, observacion varchar, iddeuda bigint, idcentrodeuda integer, idpago bigint, idcentropago integer, idprestador bigint  );
 

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

CREATE TEMP TABLE tablacompdeuda as (
  SELECT CASE WHEN idconcepto=387 THEN '10321' ELSE nrocuentac END nrocuentac, idcomprobante, saldo, idconcepto, nrodoc, tipodoc
  FROM cuentacorrientepagos JOIN recibo ON (idcomprobante= idrecibo AND idcentropago=centro)
  WHERE idrecibo=$1 AND centro=$2);

  

OPEN cpagos FOR SELECT concat(nombres, ', ', apellido ) as nomape, * FROM tablacompdeuda NATURAL JOIN persona ;
 
FETCH cpagos into ralerta;
WHILE  found LOOP




INSERT INTO tempordenpago (idordenpagotipo, nrocuentachaber,idvalorescaja,idprestador,nroordenpago,fechaingreso,beneficiario,concepto,importetotal) 
(
SELECT 4 as idordenpagotipo, '60151' as nrocuentachaber, 0 as idvalorescaja,0 as idprestador,null as nroordenpago,current_date as fechaingreso
,concat('MP /',ralerta.nomape,' DNI:',ralerta.nrodoc) as beneficiario,concat('MP/  imputar el Recibo <',ralerta.idcomprobante,'> $',abs(ralerta.saldo),'Concepto: ',ralerta.idconcepto) as concepto,abs(ralerta.saldo) as importetotal
);

INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
(
SELECT ralerta.nrocuentac::integer as codigo, ralerta.nrocuentac as nrocuentac,abs(ralerta.saldo) as debe, 0 as haber 

);
 
SELECT INTO vminuta * FROM generarordenpagogenerica();
DELETE FROM tempordenpago;
DELETE FROM tempordenpagoimputacion; 

-- La deuda El mov concepto tiene que quedar el nro de minuta
INSERT INTO tempconsumoasi(idconsumoasi,nrodoc,tipodoc,caimporte,caconcepto,idconcepto) (
 
SELECT 0 as idconsumoasi,ralerta.nrodoc,ralerta.tipodoc, abs(ralerta.saldo) as caimporte,concat('Generada desde MP:',vminuta,' para resolver error de descuento.') as caconcepto,ralerta.idconcepto

);
PERFORM migrarconsumodesdeasiV2();
DELETE FROM tempconsumoasi;

 

FETCH cpagos into ralerta;
END LOOP;
close cpagos;


END;
$function$
