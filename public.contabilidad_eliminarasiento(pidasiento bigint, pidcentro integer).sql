CREATE OR REPLACE FUNCTION public.contabilidad_eliminarasiento(pidasiento bigint, pidcentro integer)
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
rasiento record;
BEGIN
     -- 1 guardo la info del asiento que se desea eliminar 


         /*ESTA FIJA SILVI DE PRUEBA PERO SE DEBE OBTENER DE LA APP*/
         
	 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
	 IF NOT FOUND THEN
               rusuario.idusuario = 25;
               -- RAISE EXCEPTION 'No puede eliminarse un asiento si no es un usuario habilitado';
	 ELSE
        
		elidusuario = rusuario.idusuario ;
          END IF;

        RAISE NOTICE 'lo que trae pidasiento por parametro (%)',pidasiento;
	
         SELECT INTO rasiento *
         FROM   asientogenerico 
         LEFT JOIN contabilidad_ejerciciocontable USING (idejerciciocontable) 
         WHERE idasientogenerico=pidasiento AND idcentroasientogenerico = pidcentro
               AND nullvalue(eccerrado) 
 ;
            
 RAISE NOTICE  'el ejercicio contable(%) ' , rasiento ;
         IF FOUND  THEN  -- VAS 30/05/22 Es un asiento de un ejercicio contable que esta abierto
                INSERT INTO asientogenerico_borrados( agbidusuario,agtipoasiento ,    agfechacontable ,    idmultivac,    idasientogenerico ,   idcentroasientogenerico ,    agdescripcion,    agerror ,    idcentroasientogenericorevertido ,   idasientogenericorevertido ,    idcomprobantesiges ,    idasientogenericotipo ,    idasientogenericocomprobtipo ,    idagquienmigra ,    idejerciciocontable ,    agfechacreacion ,    agidusuario ,    idcentroorigenasiento ,    agnumeroasiento )
(SELECT  elidusuario, agtipoasiento ,    agfechacontable ,    idmultivac,    idasientogenerico ,   idcentroasientogenerico ,    agdescripcion,    agerror ,    idcentroasientogenericorevertido ,   idasientogenericorevertido ,    idcomprobantesiges ,
    idasientogenericotipo ,    idasientogenericocomprobtipo ,    idagquienmigra ,    idejerciciocontable ,    agfechacreacion ,    agidusuario ,    idcentroorigenasiento ,    agnumeroasiento 
               FROM asientogenerico 
               WHERE idasientogenerico=pidasiento AND idcentroasientogenerico = pidcentro);


                INSERT INTO asientogenericoitem_borrados (idasientogenerico, idcentroasientogenerico, idasientogenericoitem, idcentroasientogenericoitem, acimonto, nrocuentac, acidescripcion, acid_h, acicentrocosto, acimontoconformato)(SELECT idasientogenerico, idcentroasientogenerico, idasientogenericoitem, idcentroasientogenericoitem, acimonto, nrocuentac, acidescripcion, acid_h, acicentrocosto, acimontoconformato
                    FROM asientogenericoitem
                    WHERE  idasientogenerico=pidasiento AND idcentroasientogenerico = pidcentro  );
 

                 
                 DELETE FROM asientogenericoestado WHERE idasientogenerico=pidasiento AND idcentroasientogenerico = pidcentro;
                 DELETE FROM asientogenericoitem WHERE idasientogenerico=pidasiento AND idcentroasientogenerico = pidcentro;
                 DELETE FROM asientogenerico WHERE idasientogenerico=pidasiento AND idcentroasientogenerico = pidcentro;

                 -- si el asiento es la reversion de otro asiento entonces debe quedar en null la referencia a ese asiento
                 UPDATE asientogenerico SET idasientogenericorevertido = null ,idcentroasientogenericorevertido = null
                 WHERE idasientogenericorevertido = pidasiento  AND idcentroasientogenericorevertido =pidcentro;


           ELSE 
              RAISE EXCEPTION 'No puede eliminar un asiento que corresponde a un ejercicio cerrado';

      END IF;
RETURN true;
END;
$function$
