CREATE OR REPLACE FUNCTION public.contabilidad_eliminarasiento(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$-- Parámetros
-- $1 idasientogenerico
-- $2 idcentroasientogenerico 


DECLARE
        -- Este SP se usa para ELIMINAR un asiento.
        -- OJO !!! : el unico motivo por el cual se puede eliminar un asiento es: se genero desbalanceado o es igual al existente del comprobante.
elidusuario bigint;
rusuario record;
rfiltros record;
rasiento record;
BEGIN

      EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

     -- 1 guardo la info del asiento que se desea eliminar 


         /*ESTA FIJA SILVI DE PRUEBA PERO SE DEBE OBTENER DE LA APP*/
         
	 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	 IF NOT FOUND THEN
              elidusuario = 25;
               -- RAISE EXCEPTION 'No puede eliminarse un asiento si no es un usuario habilitado';
	 ELSE
        
		elidusuario = rusuario.idusuario ;
          END IF;

         SELECT INTO rasiento *
         FROM   asientogenerico 
         JOIN contabilidad_ejerciciocontable USING (idejerciciocontable) 
         WHERE idasientogenerico=rfiltros.idasientogenerico AND idcentroasientogenerico = rfiltros.idcentroasientogenerico
                AND nullvalue(eccerrado) ;
       
       IF FOUND  THEN  -- VAS 30/05/22 Es un asiento de un ejercicio contable que esta abierto


                INSERT INTO asientogenerico_borrados( agbidusuario,agtipoasiento ,    agfechacontable ,    idmultivac,    idasientogenerico ,   idcentroasientogenerico ,    agdescripcion,    agerror ,    idcentroasientogenericorevertido ,   idasientogenericorevertido ,    idcomprobantesiges ,    idasientogenericotipo ,    idasientogenericocomprobtipo ,    idagquienmigra ,    idejerciciocontable ,    agfechacreacion ,    agidusuario ,    idcentroorigenasiento ,    agnumeroasiento,agmotivo	 )
(SELECT  elidusuario, agtipoasiento ,    agfechacontable ,    idmultivac,    idasientogenerico ,   idcentroasientogenerico ,    agdescripcion,    agerror ,    idcentroasientogenericorevertido ,   idasientogenericorevertido ,    idcomprobantesiges ,
    idasientogenericotipo ,    idasientogenericocomprobtipo ,    idagquienmigra ,    idejerciciocontable ,    agfechacreacion ,    agidusuario ,    idcentroorigenasiento ,    agnumeroasiento ,'Desde SP contabilidad_eliminarasiento'
/* case when nullvalue(rfiltros.motivo) then '' else rfiltros.motivo end */
               FROM asientogenerico 
               WHERE idasientogenerico=rfiltros.idasientogenerico AND idcentroasientogenerico = rfiltros.idcentroasientogenerico);


                INSERT INTO asientogenericoitem_borrados (idasientogenerico, idcentroasientogenerico, idasientogenericoitem, idcentroasientogenericoitem, acimonto, nrocuentac, acidescripcion, acid_h, acicentrocosto, acimontoconformato)(SELECT idasientogenerico, idcentroasientogenerico, idasientogenericoitem, idcentroasientogenericoitem, acimonto, nrocuentac, acidescripcion, acid_h, acicentrocosto, acimontoconformato
                    FROM asientogenericoitem
                    WHERE  idasientogenerico=rfiltros.idasientogenerico AND idcentroasientogenerico = rfiltros.idcentroasientogenerico  );
 


                 DELETE FROM asientogenericoestado WHERE idasientogenerico=rfiltros.idasientogenerico AND idcentroasientogenerico = rfiltros.idcentroasientogenerico;
                 DELETE FROM asientogenericoitem WHERE idasientogenerico=rfiltros.idasientogenerico AND idcentroasientogenerico = rfiltros.idcentroasientogenerico;
                 DELETE FROM asientogenerico WHERE idasientogenerico=rfiltros.idasientogenerico AND idcentroasientogenerico = rfiltros.idcentroasientogenerico;
                
                 -- si el asiento es la reversion de otro asiento entonces debe quedar en null la referencia a ese asiento
                 UPDATE asientogenerico SET idasientogenericorevertido = null ,idcentroasientogenericorevertido = null
                 WHERE idasientogenericorevertido = rfiltros.idasientogenerico  AND idcentroasientogenericorevertido = rfiltros.idcentroasientogenerico;

      ELSE 
              RAISE EXCEPTION 'No puede eliminar un asiento que corresponde a un ejercicio cerrado';

      END IF;
RETURN true;
END;$function$
