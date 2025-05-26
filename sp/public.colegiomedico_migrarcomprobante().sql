CREATE OR REPLACE FUNCTION public.colegiomedico_migrarcomprobante()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* Se ingresan los datos de la recepcionÂº*/

DECLARE
       regtemp record;
       regfactorden record;
       elcomprobante record;
       regresumen record;
       dato record;
       curcomprobante refcursor;
       regcomprobante record;
       letrvalida record;
       elidrecep integer;
       elidcentrorecep	integer ;	
       elidrecepcion	 varchar ;	
       idrecepcomp varchar;
       aniorec varchar;
       impexento DOUBLE PRECISION;
       impnogravado DOUBLE PRECISION;
        lafecharecepcion DATE;


BEGIN
       CREATE TEMP TABLE temprecepcion (

			paraauditoria BOOLEAN DEFAULT true,
			idrecepcion INTEGER,
			fechavenc DATE,
			numfactura bigint,
			monto DOUBLE PRECISION,
			numeroregistro BIGINT,
			idprestador INTEGER,
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
			fecharecepcion DATE);
		CREATE TEMP TABLE temprecepcioncc (
							idrecepcion INTEGER,
							idcentroregional INTEGER DEFAULT centro(),
				 			idcentrocosto INTEGER DEFAULT 1,
				            monto DOUBLE PRECISION
				 );	
		       	
        elidrecep = null;	
       	elidcentrorecep = null;	
       	lafecharecepcion = now();

       OPEN curcomprobante FOR
            SELECT *
            FROM tempfactcolegiomedico
            JOIN colegiomedico_facturacionorden
                 ON(tempfactcolegiomedico.idcmfacturacionorden =colegiomedico_facturacionorden .idcmfacturacionorden )
            WHERE nullvalue(colegiomedico_facturacionorden.nroregistro);
            -- corroboro que no se intente migrar un comprobante que ya fue migrado
             FETCH curcomprobante INTO regcomprobante;
             WHILE  found LOOP

                    /*Corroboro el tipo IVA con el la letra del comprobante */
                    SELECT INTO letrvalida  idtipo,desccomprobanteventa
                    FROM relacionclientecomprobanteventa
                    NATURAL JOIN condicioniva
                    NATURAL JOIN tipocomprobanteventa
                    WHERE  ( idtipo,desccomprobanteventa)IN(
                           SELECT idcondicioniva,split_part(cmnrofactura, '-', 1)as letra
                           FROM colegiomedico_facturacionorden cm
                           join prestador  a ON ( trim(both '' from replace(cmcuit,'-','')) = trim(both '' from replace(pcuit,'-','')))
                           WHERE  idcmfacturacionorden = regcomprobante.idcmfacturacionorden);
                   -- IF FOUND THEN
            /*     SELECT INTO regfactorden *
                 FROM colegiomedico_facturacionorden
                 WHERE idcmfacturacionorden = regcomprobante.idcmfacturacionorden;
              */

                 SELECT INTO  regresumen *
                        FROM reclibrofact
                         JOIN factura on (reclibrofact.anio = factura.anio
                                     and reclibrofact.numeroregistro = factura.nroregistro)
                        WHERE reclibrofact.anio = regcomprobante.anio
                              and  numeroregistro =  regcomprobante.nroregistro;
                 if found THEN
                         elidrecep = regresumen.idrecepcion;
                         elidcentrorecep = regresumen.idcentroregional;
                         lafecharecepcion = regresumen.ffecharecepcion;
                 END IF;
                 SELECT INTO dato
                        cm.cmingresado::date + 45 as fechavenc,  cm.cmimptotalpentera::float / 100 as imptotal,
                        a.idprestador as idprestador , c.idlocalidad as idlocalidad, 1 as idtipocomprobante,cm.cmimpivapentera::float / 100  as impiva,
                        split_part(cmnrofactura, '-', 1) as clase,mcg.idcategoriagastosiges as catgasto,a.idcondicioncompra as condcompra,

                        split_part(cmnrofactura, '-', 3) ::bigint as numerofact

                        ,split_part(cmnrofactura, '-', 2) as sucursal,
                        concat('GA: Prestaciones ',extract('month' from  CURRENT_DATE)::integer -1,'/',extract('year' from  CURRENT_DATE)) as obs
                 FROM colegiomedico_facturacionorden cm
                        join prestador  a ON   ( trim(both '' from replace(cmcuit,'-','')) = trim(both '' from replace(pcuit,'-','')))
                        LEFT join multivac.mapeoprestadores mp on (a.idprestador=mp.idprestadorsiges) 	
                        left join direccion d on a.iddomiciliolegal=d.iddireccion and a.idcentrodomiciliolegal=d.idcentrodireccion 	
                        left join localidad c on d.idlocalidad=c.idlocalidad	
                        left join provincia pr on d.idprovincia=pr.idprovincia	
                        LEFT JOIN  multivac.mapeocatgasto mcg ON nrocuentacproveedor = a.nrocuentac
                 WHERE  cm.cmcuit =  regcomprobante.cmcuit
                        and idcmfacturacionorden = regcomprobante.idcmfacturacionorden ;

                 --tipocompmultivac
                 SELECT INTO elcomprobante *
                        FROM multivac.mapeotalonarios
                        WHERE   idtalonario = regcomprobante.idtipocomprobante;

                 IF (regcomprobante.cminscripto) THEN
                        impexento = regcomprobante.importe;
                        impnogravado = 0;
                 ELSE
                         impexento = 0;
                        impnogravado = regcomprobante.importe;
                 END IF;
                 
         
                 -- lleno la temporal con la informacion que espera el SP insertarrecepcion
                 INSERT INTO temprecepcion ( idrecepcion, idcentroregional,fechavenc,numfactura,monto,numeroregistro,anio,idprestador, idlocalidad,
                              idtipocomprobante,idcentroregionalresumen,idrecepcionresumen,
                              clase,montosiniva,descuento, recargo,
                              exento,
                              fechaemision,fechaimputacion,catgasto,condcompra,talonario,iva21,iva105,
                              iva27,letra,netoiva105,netoiva21
                              ,netoiva27,
                              nogravado,
                              numero,obs,percepciones,puntodeventa,retganancias,retiibb,retiva,subtotal,
                              tipocambio, tipofactura,
                              fecharecepcion)
                 VALUES (0,0,dato.fechavenc,
                (concat(trim(dato.sucursal),trim(lpad(dato.numerofact, 8, '0')))::integer ),
                 regcomprobante.importe,null,null,dato.idprestador,dato.idlocalidad
                 ,regcomprobante.idtipocomprobante,
                  elidcentrorecep,elidrecep,
                   dato.clase,(regcomprobante.importe - regcomprobante.importeiva),0,0,
                   impexento,
                   regcomprobante.fechaemision,CURRENT_DATE,dato.catgasto,
                   dato.condcompra,1,0,regcomprobante.importeiva,0,dato.clase,regcomprobante.importeiva,0,0,
                   impnogravado,
                   dato.numerofact,
                   dato.obs,0,dato.sucursal,0,0,0,0,1,elcomprobante.tipocompmultivac, lafecharecepcion);

                 INSERT INTO temprecepcioncc (  monto) VALUES (regcomprobante.importe);

                 SELECT INTO elidrecepcion insertarrecepcion();

                 SELECT INTO idrecepcomp substring(elidrecepcion from 1 for position('/' in elidrecepcion)-1 );
                 SELECT INTO aniorec substring(elidrecepcion from position('/' in elidrecepcion)+1 for char_length(elidrecepcion) );
                 -- numeroregistro anio
                 UPDATE colegiomedico_facturacionorden
                         SET nroregistro = idrecepcomp::integer ,
                          anio = aniorec::integer,
                           cmmigrado = CURRENT_TIMESTAMP
                         WHERE idcmfacturacionorden = regcomprobante.idcmfacturacionorden;
                 FETCH curcomprobante INTO regcomprobante;
               --END IF;
        END LOOP;
        CLOSE curcomprobante;


RETURN elidrecepcion;
END;
$function$
