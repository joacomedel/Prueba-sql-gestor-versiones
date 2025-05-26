CREATE OR REPLACE FUNCTION public.asientogenerico_regenerar(bigint, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$-- Parámetros
-- $1 idcomprobante (incluye centro), ej. 10494101 equivale a id=104941*100+idcentro
-- $2 idasientogenericocomprobtipo, ej. 4 equivale a ordenpago


DECLARE
    	xobs varchar;
	xasiento bigint;
        xasientoantes bigint;
        xid bigint;
        xidc integer;
-- Este SP se usa para volver a generar los asientosgenericos
   
BEGIN

   xid = $1/100;
   xidc = $1%100;

-- CS 2019-01-28 al regenerar, hay que revertir, si existe, el asiento anterior del comprobante, si es que no esta Anulado o ya revertido
       select into xasientoantes idasientogenerico*100+idcentroasientogenerico from asientogenerico NATURAL JOIN asientogenericoestado  
where nullvalue(idasientogenericorevertido) and idasientogenericocomprobtipo=$2 and idcomprobantesiges=concat(xid,'|',xidc) and nullvalue(agefechafin) and tipoestadofactura<>5;
       if found then
             perform asientogenerico_revertir(xasientoantes);
       end if;
--                    ----------------------------------------------------------------------------

IF (not iftableexistsparasp('tasientogenerico') ) THEN 
     if $2<>5 then            
                 CREATE TEMP TABLE tasientogenerico (
		                idoperacion bigint,
		                idcentroperacion integer DEFAULT centro(),
		                operacion varchar,
		                obs varchar,
		                centrocosto int,
                        idasientogenericocomprobtipo integer
                 )WITHOUT OIDS;
     else
                CREATE TEMP TABLE tasientogenerico (
		                idoperacion varchar,
		                idcentroperacion integer DEFAULT centro(),
		                operacion varchar,
		                obs varchar,
		                centrocosto int,
                        idasientogenericocomprobtipo integer
                 )WITHOUT OIDS;
     end if;
ELSE 
     /*DROP TABLE tasientogenerico;
     if $2<>5 then            
                 CREATE TEMP TABLE tasientogenerico (
		                idoperacion bigint,
		                idcentroperacion integer DEFAULT centro(),
		                operacion varchar,
		                obs varchar,
		                centrocosto int,
                        idasientogenericocomprobtipo integer
                 )WITHOUT OIDS;
     else
                CREATE TEMP TABLE tasientogenerico (
		                idoperacion varchar,
		                idcentroperacion integer DEFAULT centro(),
		                operacion varchar,
		                obs varchar,
		                centrocosto int,
                        idasientogenericocomprobtipo integer
                 )WITHOUT OIDS;
     end if;*/
     DELETE FROM tasientogenerico;
END IF;

xobs=concat('Regeneracion Manual ','id: ',$1,' - tipo: ',$2);

INSERT INTO tasientogenerico(idoperacion,
--fechaimputa,obs,idasientogenericocomprobtipo,centrocosto) 
obs,idasientogenericocomprobtipo,centrocosto) 
--             VALUES(	$1,now(),  xobs, $2,centro());
               VALUES(	$1, xobs, $2,centro());

select into xasiento asientogenerico_crear();
 
RETURN xasiento;
END;

$function$
