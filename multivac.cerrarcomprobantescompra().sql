CREATE OR REPLACE FUNCTION multivac.cerrarcomprobantescompra()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
    ctemporal refcursor;
    regtemp RECORD;
    regtemp2 RECORD;
    regtemp3 RECORD;	


BEGIN

--CS 2018-08-22 para registrar la fechaimputacion efectivamente migrada a multivac
IF not existecolumtemp('tempcompmigrado', 'fechaimputacion') THEN 
        ALTER TABLE tempcompmigrado ADD COLUMN fechaimputacion DATE DEFAULT now();
END IF;

    OPEN ctemporal FOR SELECT * FROM tempcompmigrado;
    FETCH ctemporal INTO regtemp;
    WHILE  found LOOP
           UPDATE reclibrofact set idcomprobantemultivac = regtemp.idcomprobantemultivac
-- acá
,fechaimputacion=regtemp.fechaimputacion
-----------------------------------------------------------------------------------
           WHERE  numeroregistro = regtemp.nroregistro and anio = regtemp.anio;

           select into regtemp2 *
           from reclibrofact
           WHERE numeroregistro = regtemp.nroregistro  and anio =regtemp.anio;

           if found then
                 --Agrega idcomprobanteMultivac en multivac.mapeocompcompras
                 UPDATE mapeocompcompras set idcomprobantemultivac = regtemp.idcomprobantemultivac
                        ,update = 'false'
                        ,tipomov='S'
                        ,fechaupdate= CURRENT_TIMESTAMP
                 WHERE  idrecepcion = regtemp2.idrecepcion and idcentroregional = regtemp2.idcentroregional;
           end if;
		
		   select into regtemp3 *
           from factura
           WHERE nroregistro = regtemp.nroregistro  and anio =regtemp.anio;
		
		   if found then
				--Agrega idcomprobanteMultivac en factura
                UPDATE factura set idcomprobantemultivac = regtemp.idcomprobantemultivac
                WHERE  nroregistro = regtemp.nroregistro  and anio =regtemp.anio;
                --Inserta en FEstados
-- CS 2017-10-26 Queda deshabilitado el cambio de estado... pues no tiene sentido.
--                INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion)
--                VALUES (CURRENT_DATE,regtemp.nroregistro,regtemp.anio,7,'Desde modulo siges/multivac');
		   end if;	
		
         FETCH ctemporal INTO regtemp;
    END LOOP;
CLOSE ctemporal;

RETURN true;
END;
$function$
