CREATE OR REPLACE FUNCTION public.contabilidad_generarrechazotransferencia()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       c_pagorechazado refcursor;
       rpago record;
      asientodescripcion varchar;
      rcuentadebe record;
BEGIN
     --- busco informacion del pago del la op que se rechazo la transferencia
     /* Creo las temporales para generar los asientos */

     IF not iftableexistsparasp('tasientogenerico') THEN
          CREATE TEMP TABLE tasientogenerico (    fechaimputa date,    agdescripcion character varying,    idcomprobantesiges character varying(200) DEFAULT '0|0',    idasientogenericotipo integer DEFAULT 1,    idasientogenericocomprobtipo integer DEFAULT 6);
     END IF;
     IF not iftableexistsparasp('tasientogenericoitem') THEN
          CREATE TEMP TABLE tasientogenericoitem (    acimonto double precision NOT NULL,    nrocuentac character varying NOT NULL,    acidescripcion character varying,    acid_h character varying(1) NOT NULL);
     END IF;
     -- consulta para obtener informacion de la cuenta y los importes del DEBE
     OPEN c_pagorechazado FOR SELECT *
                               FROM pagoordenpagocontable
                               NATURAL JOIN valorescaja
                               JOIN multivac.formapagotiposcuentafondos USING(idvalorescaja)
                               JOIN multivac.mapeocuentasfondos USING (idcuentafondos)
                               NATURAL JOIN tmppagoordenpagocontable
                               WHERE nrosucursal =1  ; --- OJO CUANDO se COMIENCEN A GENERAR OPC CENTRO hay que poner la sucursal por defecto del centro

     FETCH c_pagorechazado into rpago;
     WHILE FOUND LOOP
                    -- Genero un asiento de rechazo de transferencia por cada una de las transferencias rechazadas
                   asientodescripcion =concat ( 'R.T. ','OPC ', concat(rpago.idordenpagocontable,'|',rpago.idcentroordenpagocontable),' '
                                                ,rpago.popobservacion);
                   INSERT INTO tasientogenerico (fechaimputa,agdescripcion) VALUES(bofechapago,asientodescripcion);
                   INSERT INTO tasientogenericoitem (nrocuentac,acimonto ,acidescripcion,acid_h) values (  rpago.nrocuentac,rpago.popmonto ,asientodescripcion,'D');

                   -- Imputaciones HABER
                    SELECT into rcuentadebe *
                    FROM asientogenerico
                    NATURAL JOIN asientogenericoitem
                    WHERE idcomprobantesiges = concat(rpago.idordenpagocontable,'|',rpago.idcentroordenpagocontable)
                          and idasientogenericocomprobtipo = 1 -- es una opc
                          and nullvalue(idasientogenericorevertido) -- el asiento no esta revertido
                          and acid_h = 'D' ;-- Me interesa la cuenta en la que se imputo el debe

                   INSERT INTO tasientogenericoitem (nrocuentac,acimonto ,acidescripcion,acid_h) values (  rpago.nrocuentac,rpago.popmonto ,asientodescripcion,'H');
     FETCH c_pagorechazado into rpago;
     END LOOP;
     CLOSE c_pagorechazado;

     RETURN TRUE;
END;
$function$
