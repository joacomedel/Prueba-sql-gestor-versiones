CREATE OR REPLACE FUNCTION public.asientogenerico_regenerar(character varying, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$-- Parámetros
-- $1 idcomprobante (incluye centro), ej. 1049412019     ej. nroregistroanio
-- $2 idasientogenericocomprobtipo, ej. 7 equivale a compra

DECLARE
        curasiento refcursor;
        regasiento RECORD;
        xobs varchar;
        xasiento bigint;
        xasientoantes bigint;
        existe_asiento_comprobante boolean;
        resp  boolean;
        -- Este SP se usa para volver a generar los asientosgenericos
   xidasientonuevo bigint;
   xauxiliar bigint;
   xidcentroasientonuevo integer;
BEGIN
        xasiento = null;
IF (centro() <> 99) THEN 
       -- CS 2019-01-28 al regenerar, hay que revertir, si existe, el asiento anterior del comprobante, si es que no esta Anulado o Revertido
       -- VAS solo se regenera un asiento si no es igual al existente
       -- CS 2019-02-19 hay que Revertir TODOS los asientos de un comprobante antes de regenerar
        ------------------------------------------------------------------------------------------------------------------------------------------------------------
       IF (iftableexistsparasp('tasientogenerico')) THEN
          DROP TABLE tasientogenerico;
       END IF;

       CREATE TEMP TABLE tasientogenerico (
                        idasientogenerico bigint,
                        idcentroasientogenerico integer,
                        idoperacion varchar,
                        idcentroperacion integer DEFAULT centro(),
                        operacion varchar,
                        obs varchar,
                        centrocosto int,
                        modificacomprobante boolean,
                        idasientogenericocomprobtipo integer
        )WITHOUT OIDS;

        -- 22-03 comento para que la observacion se genere igual
        -- xobs=concat('R.M ',to_char(now(), 'DD-MM-YYYY'),' id: ',$1,' tipo: ',$2);
        xobs = '';

        INSERT INTO tasientogenerico(idoperacion, obs,idasientogenericocomprobtipo,centrocosto) VALUES( $1, xobs, $2::bigint,centro());
        SELECT INTO xasiento asientogenerico_crear();
         -- VAS y BelenA, 06/09/24 obtenemos id del asiento y el centro para poder comparar bien que no sea igual el nuevo a alguno ya existente
        SELECT INTO xidasientonuevo SUBSTRING (xasiento::text , 0,length(xasiento::text)-1);
        SELECT INTO xidcentroasientonuevo SUBSTRING (xasiento::text , length(xasiento::text)-1);
--RAISE EXCEPTION '1 2 xidasientonuevo,xidcentroasientonuevo    %,  %,  %,  % '  ,$1,$2,xidasientonuevo,xidcentroasientonuevo;
        SELECT INTO existe_asiento_comprobante * FROM  asientogenerico_esigual($1,$2,xidasientonuevo,xidcentroasientonuevo);
        IF  existe_asiento_comprobante THEN
            SELECT INTO resp contabilidad_eliminarasiento(xidasientonuevo,xidcentroasientonuevo);
        ELSE
              OPEN curasiento FOR
                   select idasientogenerico*100+idcentroasientogenerico as xasientoantes, idasientogenerico
                   from asientogenerico
                   natural join (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) as e
                   where idasientogenericocomprobtipo=$2 and idcomprobantesiges=$1
                         and agdescripcion not ilike 'REVERSION%' 
                         and nullvalue(idasientogenericorevertido)
                         AND xidasientonuevo<>idasientogenerico;
                         /*
                             -- VAS y BelenA, 10/09/24 modificamos la forma en la que busca que el asiento 
                             -- que toma para hacer la reversión no sea el que acababa de generar
                             --- me aseguro de no tomar el asiento que se acaba de generar
                        */

                   FETCH curasiento INTO regasiento;
                   WHILE FOUND LOOP
                   RAISE NOTICE 'regasiento.xasientoantes  % '  ,regasiento.xasientoantes;
                         perform asientogenerico_revertir(regasiento.xasientoantes);
                         FETCH curasiento INTO regasiento;
                   END LOOP;
                CLOSE curasiento;
         END IF;

      
END IF;

RETURN xasiento;
END;
$function$
