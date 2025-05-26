CREATE OR REPLACE FUNCTION ca.generarminutainstitucion(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        laliquidacion varchar ;
        mindescrip varchar ;
        elmes integer;
        elanio integer ;
        laordenpago bigint;
        elcentroordenpago integer ;
        monto  double precision ;
        cursorprestador refcursor;
        cursorimputacion refcursor;
        ladenominacion varchar;
        unprestador record;
        unaimputacion record;
        rconfcuentadiferencia record;
        rminuta record;
        laliq  varchar;
        unaop varchar;
        elconcepto varchar;
        elimportetotal double precision ;
        debecalculado double precision ;
        habercalculado double precision ;
        unidordenpago bigint;
        elidprestador bigint;
        rminatneriores record;
        rparam record;
        elcodigoimp INTEGER;
        lacuentaimp varchar;
        lacuentadif integer;
        laoperacion varchar;
BEGIN
      laliquidacion = $1;
      elconcepto = '';

      elidprestador=null;
     
     
      EXECUTE sys_dar_filtros($1) INTO rparam; 
      elmes=rparam.liqmes;
      elanio=rparam.liqanio;
      laoperacion=rparam.operacion;
      
      
      
     
     -- creo la temporal de la minuta de pago
     CREATE TEMP TABLE tempordenpago (idprestador bigint,nroordenpago   bigint,fechaingreso date ,beneficiario  character varying
     ,concepto  character varying, importetotal double precision,nrocuentachaber VARCHAR,idordenpagotipo integer, mpfechacontable date);

     
      -- creo la tabla temporal de las imputaciones de la minuta
      CREATE TEMP TABLE tempordenpagoimputacion  (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);

     if(laoperacion='regenerar') then

      /*Busco si la minuta ya existe y esta anulada*/
     SELECT INTO rminuta  *  FROM ca.op_liquidacion
                             natural join  ordenpago
                             NATURAL JOIN cambioestadoordenpago
                             NATURAL JOIN ordenpagoprestador
                             where nroordenpago=rparam.nroordenpago 
                             and idcentroordenpago=rparam.idcentroordenpago
                             and nullvalue (ceopfechafin) and idtipoestadoordenpago =4;
      elidprestador=rminuta.idprestador;
    end if;
        /*Si  tengo el nroorden a regenerar: busco su idprestador en ordenpagoprestador 
          y para ese unico prestador continua todo el sp tal cual.*/
      
       -- Busco los prestadores y por cada uno genero la minuta y la OP correspondiente
  
      OPEN cursorprestador FOR SELECT DISTINCT idprestador
                               FROM  ca.op_ctableconceptoconfig
                               WHERE (nullvalue(op_baja) and 

                              (nullvalue(elidprestador) and    rparam.operacion='generar')or 
            (not nullvalue(elidprestador) and idprestador=elidprestador)
                              ); 
                                    
       


    
      
       FETCH cursorprestador INTO unprestador;
       WHILE FOUND LOOP
                       -- incremento el numero de la orden de pago
                      SELECT INTO unidordenpago nextval('ordenpago_seq')  ;
                    
                        -- busco cada una de la imputaciones
                      OPEN cursorimputacion FOR
                                    SELECT idprestador,pdescripcion, op_ctableconceptoconfig.nrocuentac as codigo, op_ctableconceptoconfig.nrocuentac  ,
                                           SUM( CASE WHEN (idconcepto<>0)THEN
                                                    ca.sumaconceptoliquidacionmesanio(elmes,elanio ,idconcepto)
                                            ELSE
                                                    ca.as_getidasientosueldotipoctactblevalor (elmes,elanio ,idasientosueldotipoctactble)
                                            END ) as debe , 0 as haber  ,op_concepto
                                     FROM ca.op_ctableconceptoconfig
                                     JOIN prestador using (idprestador)
                                     WHERE idprestador = unprestador.idprestador
                               
                                      and nullvalue(op_baja) 
                                     GROUP BY  idprestador,pdescripcion,codigo	
                                     ,ca.op_ctableconceptoconfig.nrocuentac, op_concepto;
                         FETCH cursorimputacion INTO unaimputacion;
                         WHILE FOUND LOOP
                                     if elconcepto ilike '' THEN
                                             elconcepto = concat(unaimputacion.op_concepto,elmes, ' /',elanio);
                                     END IF;
                                     ladenominacion = unaimputacion.pdescripcion;
                                     elidprestador = unaimputacion.idprestador;
                                     debecalculado =  unaimputacion.debe;
                                     habercalculado = unaimputacion.haber;
                                     elcodigoimp = unaimputacion.codigo::integer;
                                     lacuentaimp = unaimputacion.nrocuentac;
                                     ---  Verifico si existe una orden de pago previa
                                     ---  para esa liquidacion  - a ese proveedor - y con la misma cuentas contable
                                     SELECT INTO rminatneriores  nroordenpago , idcentroordenpago ,SUM(debe)as debeacumulado,SUM(haber) as haberacumulado, MIN(importetotal)
                                     FROM ca.op_liquidacion
                                     NATURAL JOIN ordenpago
                                     NATURAL JOIN cambioestadoordenpago
                                     NATURAL JOIN ordenpagoimputacion
                                     WHERE limes = elmes and  lianio = elanio
                                           and  beneficiario like ladenominacion
                                     --      and  concepto like elconcepto
                                           and nrocuentachaber = 60140
                                             
                                           and codigo =elcodigoimp
                                           and nrocuentac = lacuentaimp
                                           and nullvalue (ceopfechafin) and idtipoestadoordenpago <>4
                                     GROUP BY  nroordenpago , idcentroordenpago;
                                     IF FOUND THEN
                                              ---- Se encuentra para esa liquidacion una minuta de pago para esa cuenta
                                              ---- Busco la configuracion realizada para la diferencia
                                              ---- 2 - Corrobo los valores nuevos con los generados
                                              --- Importes registrados en Minutas previas
                                              debecalculado = rminatneriores.debeacumulado - debecalculado;
                                              habercalculado = rminatneriores.haberacumulado - habercalculado;
                                              
                                              ---- El ultimo importes calculado
                                              SELECT INTO rconfcuentadiferencia *
                                              FROM ca.op_ctablediferenciaconfig
                                              WHERE ccdcctacble = lacuentaimp ;

                                             if(debecalculado>0)THEN -- El importe pagado en minutas es mayor que lo que se debia pagar
                                                    lacuentadif = rconfcuentadiferencia.ccdnegativa;
                                                     
                                              ELSE -- El importe pagado en minutas es menor que lo que se debia pagar
                                                    lacuentadif =rconfcuentadiferencia.ccdpositiva;
                                              END IF;
                                              elcodigoimp = lacuentadif;
                                              lacuentaimp = lacuentadif::varchar;
                                     END IF;
                                     -- ingresamos la imputacion siempre y cuando el importe sea > 0
                                     IF(abs(debecalculado)>0 or abs(habercalculado)>0)THEN
                                             INSERT INTO tempordenpagoimputacion (nroordenpago , codigo, nrocuentac,debe ,haber)
                                             VALUES(unidordenpago,elcodigoimp,lacuentaimp,abs(debecalculado) ,abs(habercalculado));
                                     END IF;
                                     FETCH cursorimputacion INTO unaimputacion;
                         END loop;
                     

                       -- calculo el importe total
                       SELECT INTO elimportetotal case WHEN nullvalue(SUM(debe)) THEN 0 ELSE SUM(debe) end   FROM tempordenpagoimputacion;
                       if (elimportetotal >0) THEN -- Si es 0 no hay se requiere realizar ningun pago
                                          
                                          --- VAS13/9/2017 Las ordenes de pago generadas para sueldos al realizar deben tocar la cuenta 60140 que es la cuenta puente
                                          --- VAS 16/04/17 la fecha de la minuta es la fecha actual y la de imputacion la fecha del asiento el ultimo dia de la liquidacion
                                          INSERT INTO tempordenpago (idprestador, nroordenpago   ,fechaingreso ,mpfechacontable ,beneficiario  ,concepto , importetotal,nrocuentachaber,idordenpagotipo )
                                          VALUES (elidprestador,unidordenpago,now(),((concat(elanio,'-',elmes,'-01')::date +'1 month'::interval)- '1 day'::interval)::  date,ladenominacion, elconcepto, elimportetotal,60140,5);
                                          SELECT INTO unaop public.ctactepagonoafilgeneraminuta();

                                          -- Guardo el vinculo entre la minuta y la liquidacion
                                          INSERT INTO ca.op_liquidacion (lianio, limes,nroordenpago,idcentroordenpago)VALUES(elanio, elmes,unidordenpago,centro());
                       END IF;
                       -- Dejo limpia la tabla temporal de las imputaciones y de la orden pago
                       DELETE FROM tempordenpagoimputacion;
                       DELETE FROM tempordenpago;

                       CLOSE cursorimputacion;
                  FETCH cursorprestador INTO unprestador;
      END loop;
      CLOSE cursorprestador;
      RETURN true;
END;


$function$
