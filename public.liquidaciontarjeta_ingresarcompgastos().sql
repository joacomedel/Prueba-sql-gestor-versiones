CREATE OR REPLACE FUNCTION public.liquidaciontarjeta_ingresarcompgastos()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan los datos de la recepcionÂº*/

DECLARE
       regtemp record;
       regfactorden record;
       elcomprobante record;
       regresumen record;
       dato record;
       curcomprobante refcursor;
       regcomprobante record;
        rcg  record;
       letrvalida record;
       elidrecep integer;
       elidcentrorecep  integer ;   
       elidrecepcion     varchar ;  
       idrecepcomp varchar;
       aniorec varchar;
       impexento DOUBLE PRECISION;
       impnogravado DOUBLE PRECISION;
       lafecharecepcion DATE;
       numcomp varchar;
       cgcant integer;
       regliq_tarjeta RECORD;
       imp_rlfpiibbneuquen  DOUBLE PRECISION;
       imp_rlfpiibbrionegro DOUBLE PRECISION;
       imp_rlfpiibbotrajuri  DOUBLE PRECISION;

BEGIN
       CREATE TEMP TABLE temprecepcion (

            paraauditoria BOOLEAN DEFAULT true,
            idrecepcion INTEGER,
            fechavenc DATE,
            numfactura bigint,
            monto DOUBLE PRECISION,
            numeroregistro BIGINT,
            idprestador BIGINT,
            idlocalidad INTEGER,
            idtipocomprobante INTEGER,
            idtiporecepcion INTEGER DEFAULT 6,
            idcentroregional INTEGER DEFAULT centro(),
            idcentroregionalresumen INTEGER,
            idrecepcionresumen INTEGER,
            anio INTEGER DEFAULT date_part('year'::text, ('now'::text)::date),
            clase VARCHAR(1),
            montosiniva DOUBLE PRECISION,
            descuento DOUBLE PRECISION,
            recargo DOUBLE PRECISION,
            exento DOUBLE PRECISION,
            fechaemision DATE,
            fechaimputacion DATE,
            catgasto INTEGER,
            condcompra INTEGER,
            talonario INTEGER,
            iva21 DOUBLE PRECISION,
            iva105 DOUBLE PRECISION,
            iva27 DOUBLE PRECISION,
            letra CHAR(1),
            netoiva105 DOUBLE PRECISION,
            netoiva21 DOUBLE PRECISION,
            netoiva27 DOUBLE PRECISION,
            nogravado DOUBLE PRECISION,
            numero VARCHAR(8),
            obs VARCHAR(255),
            percepciones DOUBLE PRECISION,
            puntodeventa VARCHAR(4),
            retganancias DOUBLE PRECISION,
            retiibb DOUBLE PRECISION,
            retiva DOUBLE PRECISION,
            subtotal DOUBLE PRECISION,
            tipocambio DOUBLE PRECISION,
            tipofactura VARCHAR,
                         movctacte boolean,
            fecharecepcion DATE,
                        accion VARCHAR,
                        
            rlfpiibbneuquen DOUBLE PRECISION,
            rlfpiibbrionegro DOUBLE PRECISION, 
            rlfpiibbotrajuri DOUBLE PRECISION,
            impdebcred DOUBLE PRECISION


);
    CREATE TEMP TABLE temprecepcioncc (
            idrecepcion INTEGER,
            idcentroregional INTEGER DEFAULT centro(),
            idcentrocosto INTEGER DEFAULT 1,
                    monto DOUBLE PRECISION
    );  
                
        elidrecep = null;   
        elidcentrorecep = null; 
        lafecharecepcion = now();
    

        OPEN curcomprobante FOR  SELECT *   FROM tcomprobantegastos;

        -- corroboro que no se intente migrar un comprobante que ya fue migrado
        FETCH curcomprobante INTO regcomprobante;
        WHILE  found LOOP          
                       SELECT INTO regliq_tarjeta * 
                             FROM  liquidaciontarjeta 
                             JOIN comercio using (nrocomercio) NATURAL JOIN jurisdiccion
                             WHERE idcentroliquidaciontarjeta = regcomprobante.idcentrolt  and  idliquidaciontarjeta = regcomprobante.idliquidacion;

                     

                       IF  (regcomprobante.cgaccion ilike 'modificar' or regcomprobante.cgaccion ilike 'eliminacion' )  THEN
                             -- Busco el nuemro de cupon correspondiente a la liquidacion
                             SELECT INTO numcomp ltcgnumero FROM liquidaciontarjetacomprobantegasto
                             WHERE idcentroliquidaciontarjeta = regcomprobante.idcentrolt  and  idliquidaciontarjeta = regcomprobante.idliquidacion
                                   AND nroregistro= regcomprobante.cgnroregistro AND anio= regcomprobante.cganio;

                       ELSE
                             SELECT INTO cgcant count(*)  FROM liquidaciontarjetacomprobantegasto
                             WHERE idcentroliquidaciontarjeta = regcomprobante.idcentrolt  and  idliquidaciontarjeta = regcomprobante.idliquidacion;
                             numcomp = (cgcant +1 )::varchar;
                                                        
                       END IF; 
                       -- lleno la temporal con la informacion que espera el SP insertarrecepcion
                        imp_rlfpiibbneuquen  = 0;
                        imp_rlfpiibbrionegro = 0;     
                        imp_rlfpiibbotrajuri = 0;

                                imp_rlfpiibbrionegro = regcomprobante.cgretiibbrn; 
                                imp_rlfpiibbneuquen  = regcomprobante.cgretiibbnqn; 
                                imp_rlfpiibbotrajuri = regcomprobante.cgretiibbotras;  

                       INSERT INTO temprecepcion (  idrecepcion,    idcentroregional,   fechavenc,  numfactura, monto,  numeroregistro, anio,   idprestador,    idlocalidad,idtipocomprobante,idcentroregionalresumen,  idrecepcionresumen,         clase,  montosiniva,descuento,  recargo,    exento,  fechaemision,  fechaimputacion,catgasto,condcompra,talonario,iva21,iva105, iva27,  letra,netoiva105,                        netoiva21, netoiva27,  nogravado, numero,  obs,    percepciones,puntodeventa,  retganancias,   retiibb,retiva,                          subtotal,  tipocambio, tipofactura,fecharecepcion,accion,rlfpiibbneuquen ,rlfpiibbrionegro,rlfpiibbotrajuri, impdebcred)
                       VALUES ( regcomprobante.cgidrecepcion,   regcomprobante.cgcentro,regcomprobante.cgfechaimputacion,   (concat(numcomp,trim(lpad(regcomprobante.idliquidacion::text, 8, '0')))::integer), regcomprobante.cgimporte,                 regcomprobante.cgnroregistro,regcomprobante.cganio,    regcomprobante.idprestador,  6, 12,null,null,'M', (regcomprobante.cgnetogravado21 + regcomprobante.cgnetogravado105),    0, 0,  0,  regcomprobante.cgfechaimputacion,regcomprobante.cgfechaimputacion,   7, 4,  12, regcomprobante.cgiva21, regcomprobante.cgiva105,0,'M',regcomprobante.cgnetogravado105,                       regcomprobante.cgnetogravado21,    0,  regcomprobante.cgnogravado, trim(lpad(regcomprobante.idliquidacion::text, 8, '0')),                 regcomprobante.cgobservacion,0,lpad(numcomp::text,4, '0')   ,0, regcomprobante.cgretiibb,regcomprobante.cgretiva,             (regcomprobante.cgnetogravado21 + regcomprobante.cgnetogravado105),  1,   'LIQ',lafecharecepcion  ,regcomprobante.cgaccion,imp_rlfpiibbneuquen,imp_rlfpiibbrionegro,imp_rlfpiibbotrajuri, regcomprobante.cglimpdebcred);

                       INSERT INTO temprecepcioncc (monto) VALUES (regcomprobante.cgnetogravado21 + regcomprobante.cgnetogravado105 + regcomprobante.cgnogravado);

                       SELECT INTO elidrecepcion mesaentrada_abmrecepcion();

                       SELECT INTO idrecepcomp substring(elidrecepcion from 1 for position('/' in elidrecepcion)-1 );
                       SELECT INTO aniorec substring(elidrecepcion from position('/' in elidrecepcion)+1 for char_length(elidrecepcion) );
                       -- corroboro que no exista un comprobante de gasto para ese numero de registro
                       SELECT INTO rcg * FROM liquidaciontarjetacomprobantegasto
                       WHERE nroregistro = idrecepcomp::integer
                              and anio = aniorec::integer 
                              and idliquidaciontarjeta = regcomprobante.idliquidacion
                              and idcentroliquidaciontarjeta = regcomprobante.idcentrolt;
                       IF NOT FOUND AND regcomprobante.cgaccion not ilike 'eliminacion'  THEN
                              INSERT INTO liquidaciontarjetacomprobantegasto (idliquidaciontarjeta,idcentroliquidaciontarjeta,nroregistro,anio,ltcgimportebruto,ltcgimporteneto,ltcgredondeo,ltcgnumero)
                              VALUES(regcomprobante.idliquidacion,regcomprobante.idcentrolt,idrecepcomp::integer,aniorec::integer
                 ,regcomprobante.ltcgimportebruto, regcomprobante.ltcgimporteneto , regcomprobante.ltcgredondeo, (cgcant +1 ));
                       ELSE
                                UPDATE liquidaciontarjetacomprobantegasto 
                                SET ltcgimportebruto = regcomprobante.ltcgimportebruto
                                    , ltcgimporteneto = regcomprobante.ltcgimporteneto
                                    , ltcgredondeo = regcomprobante.ltcgredondeo
                                 
                                WHERE  idliquidaciontarjeta = regcomprobante.idliquidacion and
                                       idcentroliquidaciontarjeta = regcomprobante.idcentrolt and
                                       nroregistro = idrecepcomp::integer and
                                       anio = aniorec::integer ;
                       END IF;
                 FETCH curcomprobante INTO regcomprobante;
        END LOOP;
        CLOSE curcomprobante;

RETURN elidrecepcion;
END;
$function$
