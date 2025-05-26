CREATE OR REPLACE FUNCTION public.facturacion_expendioreintegro(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD 
	relcompfacturacion RECORD;
	rlaminutare RECORD;
        restadoopc RECORD;
--VARIABLES 
	pagoencaja BOOLEAN;
	respuesta BOOLEAN;
	elidpagocontable VARCHAR;
BEGIN
	respuesta = true;
--BUSCO LOS DATOS DE LA FACTURA Y LA ORDEN QUE FUE FACTURADA
        SELECT INTO relcompfacturacion *, tipo AS idcomprobantetipos  FROM informefacturacion NATURAL JOIN informefacturacionexpendioreintegro 
 natural join reintegroorden NATURAL JOIN orden NATURAL JOIN facturaventacupon AS fvc JOIN valorescaja AS vc USING (idvalorescaja)  NATURAL JOIN consumo 
				
						WHERE nroinforme= $1 AND idcentroinformefacturacion = $2 AND NOT anulado;

--INSERTO PARA MANTENER COMPATIBILIDAD CON EL EXPENDIO DE ORDEN 
	INSERT INTO facturaorden(tipocomprobante,nrosucursal,tipofactura,  nrofactura, nroorden, centro, idcomprobantetipos)
                 VALUES(relcompfacturacion.tipocomprobante,relcompfacturacion.nrosucursal, relcompfacturacion.tipofactura,relcompfacturacion.nrofactura, relcompfacturacion.nroorden,relcompfacturacion.centro,relcompfacturacion.idcomprobantetipos);

--GENERO LA MINUTA DE PAGO SOLO SI NO HAY MP ASOCIADA AL REINTEGRO, O SI HAY ESTA ANULADA
	SELECT INTO rlaminutare * FROM reintegro NATURAL JOIN ordenpago --NATURAL JOIN cambioestadoordenpago 
		WHERE anio = relcompfacturacion.anio AND idcentroregional = relcompfacturacion.idcentroregional AND nroreintegro = relcompfacturacion.nroreintegro;-- AND nullvalue(ceopfechafin);
	IF NOT FOUND /*AND rlaminutare.idtipoestadoordenpago<>4*/ THEN --SI no tiene minuta el reintegro la genero
		SELECT INTO respuesta  generarminutapagoexpendioreintegro($1,$2);
        ELSE -- la MP existe
          UPDATE ordenpago set concepto= concat('Reintegro re-facturado en '  ,concat(relcompfacturacion.tipofactura , ' ' , to_char(relcompfacturacion.nrosucursal, '0000') , ' - ' ,  to_char(relcompfacturacion.nrofactura, '00000000')),'. ', concepto) 
          WHERE nroordenpago= rlaminutare.nroordenpago AND idcentroordenpago =rlaminutare.idcentroordenpago;

        END IF;

	
--SI LA FORMA DE PAGO ES EFECTIVO ENTONCES GENERO LA OPC, solo si la OPC no esta anulada 
   
    SELECT INTO restadoopc * FROM ordenpagocontablereintegro NATURAL JOIN ordenpagocontableordenpago NATURAL JOIN ordenpagocontableestado
    WHERE anio = relcompfacturacion.anio AND idcentroregional = relcompfacturacion.idcentroregional AND nroreintegro = relcompfacturacion.nroreintegro and nullvalue(opcfechafin) and idordenpagocontableestadotipo<>6;
    IF NOT FOUND THEN 
	SELECT INTO pagoencaja CASE WHEN (fptseaplica ilike '%Caja%') THEN true ELSE false end
		FROM valorescaja NATURAL JOIN formapagotipos WHERE idvalorescaja = relcompfacturacion.idvalorescaja;
	IF pagoencaja THEN
            SELECT INTO elidpagocontable generarordenpagodesdeinforme($1,$2);
        END IF;
    END IF; 
return respuesta;
END;
$function$
