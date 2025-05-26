CREATE OR REPLACE FUNCTION public.ctacteprestador_abmmovimiento(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Este SP crea movimientos de pago o de deudas generados manualmente. Por el momoento solo ingresa pero la idea es utilizarlo como ABM de ctacte_prestadores  */
DECLARE
       rfiltros record;
       elidprestadorctacte bigint;
       cmovimiento refcursor;
       unmovimiento record;
       rprestador record;
       elimporte  	double precision;
       elconcepto varchar;
       laordenpago  varchar;
BEGIN
       EXECUTE sys_dar_filtros($1) INTO rfiltros;
       
      -- recorro los movimientos
      OPEN cmovimiento FOR SELECT * FROM temp_movimiento;
      FETCH cmovimiento INTO unmovimiento;
      WHILE FOUND LOOP
           
            SELECT INTO rprestador *
            FROM prestadorctacte
            NATURAL JOIN prestador
            WHERE idprestador = unmovimiento.idprestador;
             
            IF(unmovimiento.tipomovimiento ='Deuda') THEN
                INSERT INTO ctactedeudaprestador(idprestadorctacte,idcomprobantetipos,idcomprobante,fechamovimiento,movconcepto,nrocuentac,importe,saldo,fechavencimiento)
                VALUES(rprestador.idprestadorctacte,12,nextval('ctactedeudaprestador_iddeuda_seq'),unmovimiento.fechamovimiento,unmovimiento.movconcepto,rprestador.nrocuentac,unmovimiento.importe,unmovimiento.importe,unmovimiento.fechamovimiento);
                elimporte = unmovimiento.importe;
                elconcepto = concat( ' | MINUTA IMPUTACION ',centro(),'-',currval('ctactedeudaprestador_iddeuda_seq'),': ',unmovimiento.movconcepto);
            END IF;

            IF(unmovimiento.tipomovimiento ='Pago') THEN
                elimporte = abs(unmovimiento.importe);
                INSERT INTO ctactepagoprestador(idprestadorctacte,idcomprobantetipos,idcomprobante,movconcepto,nrocuentac,importe,saldo,fechacomprobante)
                VALUES(rprestador.idprestadorctacte,12,nextval('ctactepagoprestador_idpago_seq'),unmovimiento.movconcepto,rprestador.nrocuentac,elimporte*-1,elimporte*-1,unmovimiento.fechamovimiento);
                elconcepto = concat( ' | MINUTA IMPUTACION ',centro(),'-',currval('ctactepagoprestador_idpago_seq'),': ',unmovimiento.movconcepto);
            END IF;


            IF (unmovimiento.generacontabilidad) THEN
            --BelenA 19/11/24 agrego el check

                IF (iftableexistsparasp('tempordenpago') ) THEN
                    DELETE FROM tempordenpago  ;
                ELSE 
                    CREATE TEMP TABLE tempordenpago  (
                    requiereopc boolean, 
                    idordenpagotipo integer, 
                    nrocuentachaber varchar,
                    idvalorescaja integer,
                    idprestador bigint,
                    nroordenpago   bigint,
                    fechaingreso date ,
                    beneficiario  character varying,
                    concepto  character varying, 
                    importetotal double precision); 
                END IF;
                IF (iftableexistsparasp('tempordenpagoimputacion') ) THEN
                    DELETE FROM tempordenpagoimputacion;
                ELSE 
                    CREATE TEMP TABLE tempordenpagoimputacion (codigo integer ,nrocuentac 	character varying , debe  	double precision , haber  	double precision , nroordenpago  bigint);
                END IF;  

                INSERT INTO tempordenpago (idordenpagotipo,requiereopc, nrocuentachaber,idvalorescaja,idprestador,fechaingreso,beneficiario,concepto,importetotal) 
                VALUES(12,false,rprestador.nrocuentac::integer,0,rprestador.idprestador,unmovimiento.fechamovimiento,rprestador.pdescripcion,elconcepto,elimporte );

                -- Cuando se realiza un pago el importe afecta a caja puente cobranza por lo que en la
                -- imputacion es la cuenta contable que debemos afectar 
                INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
                VALUES (10201  ,'10201' ,elimporte,'0');
                -- genero la minuta
                SELECT INTO laordenpago  generarordenpagogenerica() AS comprobante;
                
            END IF;
            FETCH cmovimiento INTO unmovimiento;               
      END LOOP;

RETURN true;
END;$function$
