CREATE OR REPLACE FUNCTION public.asientogenerico_liquidacionsueldo(integer, integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE
	elmes integer;
	elanio integer;
    cdatosasiento refcursor;
    regasiento record;
    rusuario record;
    elidusuario integer;
    fecha_imputacion date;
    elasiento bigint;
BEGIN
     elmes =  $1;
     elanio = $2;

     /* Se guarda la informacion del usuario que genero la orden de pago  */
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF not found THEN
            elidusuario = 25;
     ELSE
            elidusuario = rusuario.idusuario;
     END IF;

     --- 1 creo la cabecera del asiento
     CREATE TEMP TABLE tasientogenerico (
                  fechaimputa date
                 ,agdescripcion character varying
                 ,idcomprobantesiges character varying
                 ,idasientogenericotipo integer DEFAULT 1
                 ,idasientogenerico integer
                 ,idcentroasientogenerico integer
                 ,idasientogenericocomprobtipo integer DEFAULT 10
     );
     -- Fecha imputacion =  ultimo dia habil del mes
    
    fecha_imputacion =  to_timestamp(concat(elanio,'-',elmes,'-1'),'YYYY-MM- DD')::date+ interval '1 month' -'1 day' ::interval;
	

 /*   update  ca.asientosueldo set asfecha=fecha_imputacion where limes=elmes and lianio=elanio;*/
	


    INSERT INTO tasientogenerico (fechaimputa,agdescripcion,idcomprobantesiges) VALUES(fecha_imputacion,concat('Liq. haberes:',elmes,'/',elanio),concat(elmes,'|',elmes));

    -- 2 creo la temporal de los item del asiento,
	CREATE TEMP TABLE tasientogenericoitem (
                acimonto double precision NOT NULL,
                nrocuentac character varying NOT NULL,
                acidescripcion character varying,
                idcentrocosto integer,
                acid_h character varying(1) NOT NULL);

    -- 3 busco la info de los items
    OPEN cdatosasiento FOR
              SELECT         nrocuentac, desccuenta,idcentrocosto,
                      nombrecentrocosto
                      ,SUM(  ascimporte  ) as ascimporte
                      ,case when ascactivo THEN 'H' ELSE 'D' END as ascactivo
             FROM ca.asientosueldo
             NATURAL JOIN ca.asientosueldotipoctactble
             NATURAL JOIN ca.asientosueldoctactble
             NATURAL JOIN cuentascontables
             NATURAL JOIN centrocosto
             NATURAL JOIN ca.asientosueldotipo
             LEFT JOIN  (	SELECT	sum(ascimporte) as haber,idasientosueldo,idasientosueldotipo
                            FROM  ca.asientosueldo
                            NATURAL JOIN ca.asientosueldotipoctactble
                            NATURAL JOIN ca.asientosueldoctactble
                            WHERE limes=elmes and lianio=elanio
                                  and nullvalue(asfecha)  and  ascactivo	
                                  and asvigente
                            GROUP BY ascactivo,idasientosueldo,idasientosueldotipo	
                         ) as infohaber  using (idasientosueldo,idasientosueldotipo)
             LEFT JOIN    ( SELECT	sum(ascimporte) as debe,idasientosueldo	,idasientosueldotipo
                            FROM  ca.asientosueldo
                            NATURAL JOIN ca.asientosueldotipoctactble
                            NATURAL JOIN ca.asientosueldoctactble
                            WHERE limes=elmes and lianio=elanio
                                 --- MODIFICAR SIGES PARA QUE NO ACTURALICE LA FECHA DEL ASIENTO  and nullvalue(asfecha)
                                  and  not ascactivo  and asvigente
                            GROUP BY ascactivo,idasientosueldo,idasientosueldotipo	
                            ) as infodebe USING (idasientosueldo,idasientosueldotipo)
             WHERE limes=elmes and lianio=elanio
                   and nullvalue(ca.asientosueldo.asfecha)  and asvigente
             GROUP BY idcentrocosto, nombrecentrocosto  ,  nrocuentac, desccuenta,ascactivo
             ORDER BY nrocuentac ;


             FETCH cdatosasiento into regasiento;

             WHILE FOUND LOOP
                    INSERT INTO tasientogenericoitem (nrocuentac,acimonto ,acidescripcion,acid_h,idcentrocosto )
                     values ( regasiento.nrocuentac, regasiento.ascimporte,regasiento.desccuenta,regasiento.ascactivo, regasiento.idcentrocosto );
             FETCH cdatosasiento into regasiento;
             END LOOP;
             SELECT INTO elasiento asientogenerico_crear();

    CLOSE cdatosasiento;


RETURN elasiento; -- deberia devolcer el idasiento
END;
$function$
