CREATE OR REPLACE FUNCTION public.asientogenerico_cambiarestadocomprobante(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$-- Parámetros
-- $1 idasientogenerico
-- $2 idcentroasientogenerico

DECLARE
	regasientoinfo record;
	regopc  record;
	resp boolean;
	elidopc bigint;
	elidcopc integer;
	elidop bigint;
	elidcop integer;

-- Este SP se usa para Cambiar el Estado del comprobante vinculado a un asiento generico, segun corresponda.
   
BEGIN

	resp=false;

	-- si el asiento generico corresponde a una OP cambio su estado a migrada 4 - // - 1 ordenpagocontable
			SELECT INTO regasientoinfo *
			    FROM asientogenerico
			    LEFT JOIN asientogenericocomprobtipo using(idasientogenericocomprobtipo)
			    WHERE idasientogenerico = $1
			          AND idcentroasientogenerico = $2;
			IF(regasientoinfo.idasientogenericocomprobtipo=1 )THEN--- 1 ordenpagocontable
		          elidopc =  split_part(regasientoinfo.idcomprobantesiges, '|',1)::bigint;
		          elidcopc = split_part(regasientoinfo.idcomprobantesiges, '|',2)::integer;
		          SELECT INTO resp  * from cambiarestadoordenpagocontable(elidopc, elidcopc, 8, concat('desde asientogenerico_cerrar ID AS:',$1)) ;
    			END IF;
-- CS 2018-02-15 Queda comentado. La migracion de la OrdenPago no implica necesariamente que la OrdenPagoContable sea marcada como sincronizada
/*
			IF(regasientoinfo.idasientogenericocomprobtipo=4 )THEN--- 4 ordenpago
		          elidop =  split_part(regasientoinfo.idcomprobantesiges, '|',1)::bigint;
		          elidcop = split_part(regasientoinfo.idcomprobantesiges, '|',2)::integer;
          		  SELECT INTO regopc * FROM ordenpagocontableordenpago
		          WHERE idcentroordenpago = elidcop AND   nroordenpago =elidop;
		
		          SELECT INTO resp * from cambiarestadoordenpagocontable(regopc.idordenpagocontable, regopc.idcentroordenpagocontable,8,concat( 'desde asientogenerico_cerrar ID AS:',$1)) ;
			END IF;
*/
		

RETURN resp;
END;

$function$
