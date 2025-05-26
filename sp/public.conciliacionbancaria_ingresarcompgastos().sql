CREATE OR REPLACE FUNCTION public.conciliacionbancaria_ingresarcompgastos()
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
       elidcentrorecep	integer ;	
       elnumeroregistro	 varchar ;	
       numregistro varchar;
       aniorec varchar;
       impexento DOUBLE PRECISION;
       impnogravado DOUBLE PRECISION;
        lafecharecepcion DATE;
	numcomp varchar;
	cgcant integer;

BEGIN
       CREATE TEMP TABLE temprecepcion (

			paraauditoria BOOLEAN DEFAULT true,
			idrecepcion INTEGER,
			fechavenc DATE,
			numfactura BIGINT,
			monto DOUBLE PRECISION,
			numeroregistro BIGINT,
			idprestador BIGINT, --  <---> cambie de integer a bigint, borrar este comentario despues
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
                        rlfpiibbneuquen DOUBLE PRECISION,
                        rlfpiibbrionegro DOUBLE PRECISION,
                        rlfpiibbotrajuri  DOUBLE PRECISION,
			retiva DOUBLE PRECISION,
			subtotal DOUBLE PRECISION,
			tipocambio DOUBLE PRECISION,
			tipofactura VARCHAR,
                         movctacte boolean,
			fecharecepcion DATE,
                        accion VARCHAR,
-- BelenA 23-10-23 agrego :
                impdebcred  DOUBLE PRECISION);
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
          IF  (regcomprobante.cgaccion ilike 'modificar' or regcomprobante.cgaccion ilike 'eliminacion' )  THEN
                    -- Busco el nuemro de cupon correspondiente a la liquidacion
                      SELECT INTO numcomp cbcgnumero FROM conciliacionbancariacomprobantegasto
                    WHERE idcentroconciliacionbancaria = regcomprobante.idcentroconciliacionbancaria  and  idconciliacionbancaria = regcomprobante.idconciliacionbancaria
                     AND nroregistro= regcomprobante.cgnroregistro AND anio= regcomprobante.cganio;

          ELSE
                   SELECT INTO cgcant count(*)  FROM conciliacionbancariacomprobantegasto
                    WHERE idcentroconciliacionbancaria = regcomprobante.idcentroconciliacionbancaria  and  idconciliacionbancaria = regcomprobante.idconciliacionbancaria;
                   numcomp = (cgcant +1 )::varchar;
          END IF;
                    -- lleno la temporal con la informacion que espera el SP insertarrecepcion

                      INSERT INTO temprecepcion (
			                 idrecepcion, 	idcentroregional,	fechavenc,	numfactura,	monto,	numeroregistro,	anio,	idprestador,	idlocalidad,		idtipocomprobante,
			                 idcentroregionalresumen,	idrecepcionresumen,       	clase,	montosiniva,descuento,	recargo,	exento,
                             fechaemision,	fechaimputacion,catgasto,condcompra,talonario,iva21,iva105,	iva27,	letra,netoiva105,
			                 netoiva21,	netoiva27,	nogravado, numero,	obs,	percepciones,puntodeventa,	retganancias,	retiibb,rlfpiibbneuquen ,rlfpiibbrionegro,rlfpiibbotrajuri ,retiva,
			                 subtotal,	tipocambio,	tipofactura,fecharecepcion,accion, impdebcred)
                      VALUES (
                             regcomprobante.cgidrecepcion,	regcomprobante.cgcentro,			regcomprobante.cgfechaimputacion,	(concat(numcomp,trim(lpad(regcomprobante.idconciliacionbancaria::text, 8, '0')))::integer),
		                     regcomprobante.cgimporte,
			                 regcomprobante.cgnroregistro,regcomprobante.cganio,	regcomprobante.idprestador,
			                 6,			1,			null,			null,			'A', (regcomprobante.cgnetogravado21 + regcomprobante.cgnetogravado105),
			                 0,	0,  0,	regcomprobante.cgfechaimputacion,regcomprobante.cgfechaimputacion,
			                 61,	3,	1,	regcomprobante.cgiva21,	regcomprobante.cgiva105,0,	'A',regcomprobante.cgnetogravado105,
			                 regcomprobante.cgnetogravado21,	0,	regcomprobante.cgnogravado,	trim(lpad(regcomprobante.idconciliacionbancaria::text, 8, '0')),
		                  	regcomprobante.cgobservacion,0,lpad(numcomp::text,4, '0')	,0,	regcomprobante.cgretiibb,regcomprobante.cgretiibbnqn,regcomprobante.cgretiibbrn,regcomprobante.rlfpiibbotrajuri,regcomprobante.cgretiva,
			               (regcomprobante.cgnetogravado21 + regcomprobante.cgnetogravado105),
			               1,	'FAC',lafecharecepcion	,regcomprobante.cgaccion,regcomprobante.impdebcred);

                      INSERT INTO temprecepcioncc (monto) VALUES (regcomprobante.cgnetogravado21 + regcomprobante.cgnetogravado105 + regcomprobante.cgnogravado);

                      SELECT INTO elnumeroregistro mesaentrada_abmrecepcion();

                      SELECT INTO numregistro substring(elnumeroregistro from 1 for position('/' in elnumeroregistro)-1 );
                      SELECT INTO aniorec substring(elnumeroregistro from position('/' in elnumeroregistro)+1 for char_length(elnumeroregistro) );
                 -- numeroregistro anio
                       -- corroboro que no exista un comprobante de gasto para ese numero de registro
                       SELECT INTO rcg * FROM conciliacionbancariacomprobantegasto
                        WHERE nroregistro = numregistro::integer
                              and anio = aniorec::integer
                              and idconciliacionbancaria = regcomprobante.idconciliacionbancaria
                              and idcentroconciliacionbancaria = regcomprobante.idcentroconciliacionbancaria;
                      IF NOT FOUND AND regcomprobante.cgaccion not ilike 'eliminacion'  THEN
                              INSERT INTO conciliacionbancariacomprobantegasto (idconciliacionbancaria,idcentroconciliacionbancaria,nroregistro,anio,cbcgimportebruto,cbcgimporteneto,cbcgredondeo,cbcgnumero)
                              VALUES(regcomprobante.idconciliacionbancaria,regcomprobante.idcentroconciliacionbancaria,numregistro::integer,aniorec::integer
                 ,regcomprobante.cbcgimportebruto, regcomprobante.cbcgimporteneto , regcomprobante.cbcgredondeo, (cgcant +1 ));
                     ELSE
                                UPDATE conciliacionbancariacomprobantegasto
                                SET cbcgimportebruto = regcomprobante.cbcgimportebruto
                                    , cbcgimporteneto = regcomprobante.cbcgimporteneto
                                    , cbcgredondeo = regcomprobante.cbcgredondeo

                                WHERE  idconciliacionbancaria = regcomprobante.idconciliacionbancaria and
                                       idcentroconciliacionbancaria = regcomprobante.idcentroconciliacionbancaria and
                                       nroregistro = numregistro::integer and
                                       anio = aniorec::integer ;
                      END IF;
                 FETCH curcomprobante INTO regcomprobante;
               --END IF;
        END LOOP;
        CLOSE curcomprobante;

RETURN  concat(numregistro::varchar,'|',aniorec::varchar);
                                       
END;
$function$
