CREATE OR REPLACE FUNCTION public.asientogenerico_esigual(pidcomprobantesiges character varying, pidasientogenericocomprobtipo integer, pidasiento bigint, pidcentro integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$-- ParÃƒÂ¡metros
-- $1 idcomprobantesiges
-- $2 idasientogenericocomprobtipo, ej. 4 equivale a ordenpago
--SELECT asientogenerico_esigual('FA|1|1|211585',5,145777,1)

DECLARE
    	xobs varchar;
	    xasiento bigint;
        xasientoantes bigint;
        xid bigint;
        xidc integer;
        igual boolean;
	    rasientogenerico record;
	    ragnuevo record;
	    cant_items_iguales integer;
        -- Este SP se usa para volver a generar los asientosgenericos
        
BEGIN
	igual = false;
    -- 1 Busco el asiento que se tenia generado
	SELECT INTO rasientogenerico * FROM asientogenerico
	                              JOIN (SELECT count(*) as cant_item ,idasientogenerico,idcentroasientogenerico
                                        FROM asientogenerico
                                        NATURAL JOIN asientogenericoitem
                                        WHERE idcomprobantesiges = pidcomprobantesiges
                                               AND agdescripcion not ilike 'REVERSION%'
                                               AND nullvalue(idasientogenericorevertido)
                                        GROUP BY idasientogenerico,idcentroasientogenerico
                                  ) as t USING(idasientogenerico,idcentroasientogenerico)
					              WHERE idcomprobantesiges = pidcomprobantesiges
  				                        AND agdescripcion not ilike 'REVERSION%'
  				                        AND nullvalue(idasientogenericorevertido)
					                    AND idasientogenericocomprobtipo = pidasientogenericocomprobtipo
					                    AND ((idasientogenerico *100) +idcentroasientogenerico) <> ((pidasiento *100) +pidcentro); -- diferente del nuevo

    --  Busco el nuevo asiento
	IF FOUND THEN
		SELECT INTO ragnuevo * FROM asientogenerico
		                       JOIN (SELECT count(*) as cant_item ,idasientogenerico,idcentroasientogenerico
                                        FROM asientogenericoitem
                                        WHERE idasientogenerico = pidasiento AND idcentroasientogenerico = pidcentro
                                        GROUP BY idasientogenerico,idcentroasientogenerico
                                ) as t USING(idasientogenerico,idcentroasientogenerico)
					WHERE idcomprobantesiges = pidcomprobantesiges
					AND idasientogenericocomprobtipo = pidasientogenericocomprobtipo
					AND idasientogenerico = pidasiento AND idcentroasientogenerico = pidcentro; -- con estos 2 campos deberia alcanzar
		IF FOUND THEN
		    -- comparo los valores de los campos que difinen un asientocontable
            -- Los campos que simbolizan cambios en la cabecera del asiento (asientogenerico): agdescripcion agfechacontable
            -- Los campos que simbolizan cambios en los item del asiento (asientogenericoitem): nrocuentac acimonto acid_h acidescripcion

--KR 11-12-20 ASUMimos que la descripcion de un asiento no lo hace unico               
                IF  ( /*ragnuevo.agdescripcion = rasientogenerico.agdescripcion
                      AND*/ ragnuevo.agfechacontable = rasientogenerico.agfechacontable
                      AND ragnuevo.cant_item = rasientogenerico.cant_item
                      ) THEN
                    -- las cavbeceras y la cantidad de item son iguales
                     RAISE NOTICE 'el viejo idasientogenerico(%)',rasientogenerico.idasientogenerico;
                      RAISE NOTICE 'el nuevo idasientogenerico(%)',ragnuevo.idasientogenerico;
                     SELECT INTO cant_items_iguales count(*) as cant
                     FROM  (SELECT nrocuentac, acimonto, acid_h, acidescripcion   -- los campos que me gustaria comparar
                            FROM asientogenerico
                            NATURAL JOIN asientogenericoitem
                            WHERE idcomprobantesiges = pidcomprobantesiges
                                  AND idasientogenerico = rasientogenerico.idasientogenerico
                                  AND idcentroasientogenerico = rasientogenerico.idcentroasientogenerico
                     ) as t
                     JOIN (SELECT nrocuentac, acimonto, acid_h, acidescripcion
                            FROM asientogenericoitem
                            WHERE idasientogenerico = pidasiento AND idcentroasientogenerico = pidcentro
                     ) as tnuevo USING(nrocuentac, acimonto, acid_h, acidescripcion);
                     -- Si la cantidad del join es = a la cantidad de item son =
                     IF(ragnuevo.cant_item = cant_items_iguales) THEN
                           
                          igual = TRUE;


                           IF (ragnuevo.agdescripcion <> rasientogenerico.agdescripcion) THEN
                               UPDATE asientogenerico SET agdescripcion =  CONCAT (rasientogenerico.agdescripcion,' ',ragnuevo.agdescripcion) 
                                WHERE idasientogenerico = ragnuevo.idasientogenerico  AND idcentroasientogenerico = ragnuevo.idcentroasientogenerico ;
                           END IF;

                     END IF;
			END IF;
		END IF;
	END IF;

RETURN igual;
END;
$function$
