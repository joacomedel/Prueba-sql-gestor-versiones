CREATE OR REPLACE FUNCTION public.sys_generar_movimiento_ctacte_prestador(pfiltros character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD
        rusuario RECORD;
        rmovctacte RECORD;
--VARIABLES
	vminuta varchar;
	vopc varchar;
	vpop varchar;
  

BEGIN

CREATE TEMP TABLE tempordenpago ( idordenpagotipo integer, nrocuentachaber varchar,idvalorescaja integer,idprestador bigint,nroordenpago   bigint,fechaingreso date ,beneficiario  character varying,concepto  character varying, importetotal double precision); 
CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);
CREATE TEMP TABLE tempcomprobante (  idcomprobante bigint,  idcomprobantetipos integer,  nrocomp varchar ,  idcentrocomp INTEGER , montopagar double precision , montoretencion double precision, apagarcomprobante double precision, tipocomp varchar, observacion varchar, iddeuda bigint, idcentrodeuda integer, idpago bigint, idcentropago integer, idprestador bigint  );
CREATE TEMP TABLE temp_movimiento (  idprestadorctacte bigint,  fechamovimiento timestamp,  movconcepto varchar ,  nrocuentac varchar , importe double precision) ;
 

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;


 
--KR 23-01-20 Genera Movimiento Cta Cte (idordenpagotipo=11) NO genera contabilidad
INSERT INTO tempordenpago (idordenpagotipo, nrocuentachaber,idvalorescaja,idprestador,nroordenpago,fechaingreso,beneficiario,concepto,importetotal) 
(
SELECT 11 as idordenpagotipo, '60151', 0 as idvalorescaja,0 as idprestador,null as nroordenpago,current_date as fechaingreso
,concat('MP /',rmovctacte.nomape,' DNI:',rmovctacte.nrodoc) as beneficiario,concat('MP/  generar Mto. Cta. Cte. de ', case when (rmovctacte.caimporte >= 0) THEN ' deuda ' ELSE ' pago. ' END,' <',rmovctacte.caconcepto,'> $',abs(rmovctacte.caimporte),' Concepto: ',rmovctacte.idconcepto) as concepto,abs(rmovctacte.caimporte) as importetotal
);

	INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) (
	SELECT rmovctacte.nrocuentac::integer as codigo, rmovctacte.nrocuentac as nrocuentac,abs(rmovctacte.caimporte) as debe, 0 as haber 
	);
 
	SELECT INTO vminuta * FROM generarordenpagogenerica();
	DELETE FROM tempordenpago;
	DELETE FROM tempordenpagoimputacion; 


	PERFORM ctacteprestador_abmmovimiento(pfiltros);

  


END;
$function$
