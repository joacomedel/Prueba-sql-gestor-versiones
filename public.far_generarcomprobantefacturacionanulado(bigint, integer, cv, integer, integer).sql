CREATE OR REPLACE FUNCTION public.far_generarcomprobantefacturacionanulado(bigint, integer, character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que genera comprobantes de facturacion anuladas 
        SELECT far_generarcomprobantefacturacionanulado(142125,4,'FA',1,1) 
        Este metodo espera el numero de comprobante desde el que se requiere realizar el cambio
	En el ultimo parametro se ordena el tipo de desplazamiento que se requiere
                            >0 => desplazamiento ascendente
                            
*/
DECLARE
     
--registros
       resultado  RECORD;
       rfactventa record;
       rfactventaant record;
       elnrofactura bigint;
       lasucursal integer;
       eltipofactura varchar;
       eltipocomprobante  integer;
       desplazamiento real;
       vfechaemision timestamp;
	rusuario record;
	elidusuario integer;
BEGIN

      elnrofactura = $1;
      lasucursal =$2;
      eltipofactura = $3;
      eltipocomprobante = $4;

      vfechaemision = now();
      ------------------------
      ---- Indica si el corrimiento es creciente o no
      -- si el valor ingresado es -1 = > retrocede la numeracion
      -- si el valor es 1 = > incrementa la numeracion
      desplazamiento = $5;
		SELECT INTO rfactventa * FROM talonario WHERE nrosucursal = lasucursal 
								AND tipocomprobante = eltipocomprobante 
								AND tipofactura = eltipofactura;

		SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
                 IF not found THEN

                     SELECT INTO rfactventaant * FROM facturaventausuario NATURAL JOIN facturaventa WHERE nrosucursal = lasucursal 
								AND tipocomprobante = eltipocomprobante 
								AND tipofactura = eltipofactura
                                                                AND nrofactura = elnrofactura-1;
                     IF FOUND THEN 
                       elidusuario = rfactventaant.idusuario;
                       vfechaemision = rfactventaant.fechaemision;
                     ELSE
                       elidusuario = 25;
                     END IF;
                 ELSE
                     elidusuario = rusuario.idusuario;
                 END IF;


     
	      FOR i IN 1..desplazamiento LOOP
	      
	               /* Se inserta la factura anulada */
                  INSERT INTO facturaventa(tipocomprobante,nrosucursal,nrofactura,tipofactura,anulada,centro,fechaemision)
		          VALUES(eltipocomprobante,lasucursal,elnrofactura,eltipofactura,vfechaemision,rfactventa.centro,vfechaemision::date);
                 /* Se guarda la informacion del usuario que genero el comprobante */
                 INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                 VALUES   (eltipocomprobante,lasucursal,elnrofactura, eltipofactura,elidusuario,elnrofactura);

                 elnrofactura = elnrofactura +1;
		END LOOP;
       
       
       
RETURN true;
END;
$function$
