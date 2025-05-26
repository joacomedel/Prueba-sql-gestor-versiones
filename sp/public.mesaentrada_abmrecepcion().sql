CREATE OR REPLACE FUNCTION public.mesaentrada_abmrecepcion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan / modifica / elimina los datos de una recepción */

DECLARE
codcomprobante BIGINT;
codrecepcion integer;
regtemp record;
idcentrorecepcion integer;
elnumeroregistro varchar;
respuesta  varchar;
rauditada RECORD;
elem RECORD;
esderesumen RECORD;
vTipomov char;
auxx integer;
rexistecomp  RECORD;

BEGIN
           RAISE NOTICE 'Hola mesaentrada_abmrecepcion';

IF not existecolumtemp('temprecepcion','idactividad') THEN 

ALTER TABLE temprecepcion ADD COLUMN idactividad INTEGER DEFAULT 1;

END IF;
        
       elnumeroregistro = '';
       SELECT INTO regtemp * FROM temprecepcion ;
       IF FOUND THEN

	    -- Verifico si se requiere eliminar el comprobante
	    if(regtemp.idrecepcion <> 0  AND regtemp.accion = 'eliminacion') THEN	
	        SELECT INTO elnumeroregistro * FROM mesaentrada_eliminarrecepcion();

	    ELSE 

                  IF not (regtemp.fechaemision >= to_char( date_trunc('month',now())-'48month' ::interval-'1sec' ::interval, 'YYYY-MM-DD' ) 
                         and regtemp.fechaemision < to_char( date_trunc('day',now())+'1day' ::interval, 'YYYY-MM-DD' )
                    )THEN
                  	-- TANTO EN LA MODIFICACION COMO LA INSERCION  21/05/2019
                        -- La fecha de emision del comprobante NO PUEDE SER > a la fecha actual + 1 ni menor a 3 meses
                        -- 5/06 La fecha de emision del comprobante NO PUEDE SER > a la fecha actual + 1 ni menor a 12 meses 
			RAISE EXCEPTION 'LA FECHA EMISION DEBE SER MAYOR O IGUAL A 1 AÑO';
                    END IF;
          --KR 06-06-22 tkt 5124
                    SELECT INTO rexistecomp * FROM reclibrofact  
                           where idprestador=regtemp.idprestador  and clase=regtemp.clase and idtipocomprobante=regtemp.idtipocomprobante
				 and numfactura=regtemp.numfactura 
                                 AND numeroregistro <> regtemp.numeroregistro  AND anio <> regtemp.anio
                                /*and idtipocomprobante<>12*/;
                    IF FOUND THEN  --EL registro ya existe
                       RAISE EXCEPTION 'El comprobante ya existe! (Nro. Registro,%)',concat(rexistecomp.numeroregistro, '-',rexistecomp.anio);
                    END IF;
	            IF (regtemp.idrecepcion = 0 ) THEN
		            SELECT INTO elnumeroregistro * FROM mesaentrada_insertarrecepcion();
	            ELSE
                  
		            SELECT INTO elnumeroregistro * FROM mesaentrada_modificarrecepcion();	
	            END IF;
	      
		    IF not nullvalue(elnumeroregistro)  AND elnumeroregistro <> '' THEN 
			      SELECT INTO  elem * FROM reclibrofact WHERE numeroregistro = trim(split_part(elnumeroregistro,'/',1))::bigint AND anio = trim(split_part(elnumeroregistro,'/',2))::integer;
			      IF FOUND THEN 
				      SELECT INTO respuesta * FROM insertarfactura(elem.idrecepcion, elem.idcentroregional);
			      END IF;
		    END IF;
		    --KR 30-01-15 corroboro si además debo hacer un movimiento en la cuenta corriente, dada la categoria de gasto
		    IF (regtemp.movctacte) THEN 
		            PERFORM ingresarmovimientoctactecatgasto();
		    END IF; 
                    --MaLaPi 16/08/2017 Si lo que viene es una factura, que esta dentro de un resumen, es posible que tenga que actualizar la fecha de emision del resumen.
                    IF not nullvalue(regtemp.idrecepcionresumen)  THEN 
                             UPDATE reclibrofact set fechaemision =(
                                      select min(fechaemision) as fechaemision
                                      from reclibrofact r 
                                      WHERE idrecepcionresumen=regtemp.idrecepcionresumen AND idcentroregionalresumen=regtemp.idcentroregionalresumen
                                      )
                              WHERE idrecepcion = regtemp.idrecepcionresumen AND idcentroregional = regtemp.idcentroregionalresumen;

                   END IF; 
	   END IF; -- Cierre del ELSE if(regtemp.idrecepcion <> 0  AND regtemp.accion = 'eliminar') THEN

      END IF;
RETURN elnumeroregistro;
END;$function$
