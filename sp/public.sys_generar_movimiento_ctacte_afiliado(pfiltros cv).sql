CREATE OR REPLACE FUNCTION public.sys_generar_movimiento_ctacte_afiliado(pfiltros character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE
	cmovctacte refcursor;
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
 

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

--KR 31-08-22 afecta al debe
CREATE TEMP TABLE tablamovctacte as (
  SELECT CASE WHEN NULLVALUE(nrocuentacontable) THEN '10201' ELSE nrocuentacontable END nrocuentac, *
  FROM  tempconsumoasi LEFT JOIN cuentacorrienteconceptotipo USING(idconcepto));

  

OPEN cmovctacte FOR SELECT concat(nombres, ', ', apellido ) as nomape, * FROM tablamovctacte NATURAL JOIN persona ;
 
FETCH cmovctacte into rmovctacte;
WHILE  found LOOP

--KR 28-05-19 por ahora la cuenta es '60151' 'Cuenta puenta - Siges'. Ver en todos los casos si es asi 
	INSERT INTO tempordenpago (idordenpagotipo, nrocuentachaber,idvalorescaja,idprestador,nroordenpago,fechaingreso,beneficiario,concepto,importetotal) 
(
--KR 31-08-22 afecta al haber
SELECT 4 as idordenpagotipo, '60151', 0 as idvalorescaja,0 as idprestador,null as nroordenpago,current_date as fechaingreso
,concat('MP /',rmovctacte.nomape,' DNI:',rmovctacte.nrodoc) as beneficiario,concat('MP/  generar Mto. Cta. Cte. de ', case when (rmovctacte.caimporte >= 0) THEN ' deuda ' ELSE ' pago. ' END,' <',rmovctacte.caconcepto,'> $',abs(rmovctacte.caimporte),' Concepto: ',rmovctacte.idconcepto) as concepto,abs(rmovctacte.caimporte) as importetotal
);

	INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) (
	SELECT rmovctacte.nrocuentac::integer as codigo, rmovctacte.nrocuentac as nrocuentac,abs(rmovctacte.caimporte) as debe, 0 as haber 
	);
 
	SELECT INTO vminuta * FROM generarordenpagogenerica();
	DELETE FROM tempordenpago;
	DELETE FROM tempordenpagoimputacion; 


	UPDATE tempconsumoasi SET caconcepto = CONCAT (caconcepto , ' ','. MP ',vminuta,' generó movimientos en la cta. cte. del afiliado. '),  nroordenpago = split_part(vminuta, '-',1)::BIGINT, idcentroordenpago = split_part(vminuta, '-',2)::INTEGER;
    
 
      --KR 05-06-19 especialización de MP para MP de afiliados
        INSERT INTO ordenpagoafiliado (nroordenpago,idcentroordenpago,nrodoc,tipodoc, opcaobservacion) VALUES(trim(split_part(vminuta, '-', 1))::bigint, trim(split_part(vminuta, '-', 2))::integer,rmovctacte.nrodoc,rmovctacte.tipodoc, 'Movimiento generado desde sys_generar_movimiento_ctacte_afiliado' );
	PERFORM migrarconsumodesdeasiV2();
	DELETE FROM tempconsumoasi;

 
        
FETCH cmovctacte into rmovctacte;
END LOOP;
close cmovctacte;


END;$function$
