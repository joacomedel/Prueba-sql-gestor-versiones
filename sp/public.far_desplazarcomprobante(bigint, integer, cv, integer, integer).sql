CREATE OR REPLACE FUNCTION public.far_desplazarcomprobante(bigint, integer, character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       elnrofactura bigint;
       desde bigint;
       hasta  bigint;
       lasucursal integer;
       eltipofactura varchar;
       eltipocomprobante  integer;
       elmayor bigint;
       cfactura refcursor;
       unfac record;
       rtemp record;
       desplazamiento real;
       
       estanfk boolean;
       respuestaeliminar boolean;
       elcomprobanteanulado bigint;
       elidusuario INTEGER;
       rcomproanulado record;
BEGIN
      -- Antes que nada verifico que existan todas las FK que deben existir para garantizar la robustez y buen funcionamiento del SP
        SELECT INTO respuestaeliminar * FROM existefkey();
        IF (not respuestaeliminar) THEN return false; END IF ;

      
       ----  Si las restricciones de cumplen


      elnrofactura = $1;
      lasucursal =$2;
      eltipofactura = $3;
      eltipocomprobante = $4;
      
      ------------------------
      ---- Indica si el corrimiento es creciente o no
      -- si el valor ingresado es -1 = > retrocede la numeracion
      -- si el valor es 1 = > incrementa la numeracion
      desplazamiento = $5;
      ------------
       elcomprobanteanulado = 0;

      SELECT INTO elmayor max(nrofactura)
      FROM facturaventa
      WHERE nrosucursal=lasucursal
            and tipofactura = eltipofactura
            and tipocomprobante = eltipocomprobante;

     desde =elnrofactura ;
     hasta = elmayor;
     --hasta = 171193;
      IF (desplazamiento >0 ) THEN 
            elnrofactura = hasta;
            --elnrofactura = elmayor;
         -- Malapi 05-01-2015 Si se incrementa la numeracion, hay que guardar el comprobante original, para al final del proceso, generar un comprobante anulado. IMPORTANTE: solo funciona cuando se desplaza un numero, en otros caso hay que generar los otros comprobantes anulados a mano.    
         elcomprobanteanulado = desde;
         SELECT INTO rcomproanulado * FROM facturaventausuario NATURAL JOIN facturaventa WHERE nrofactura =elcomprobanteanulado and nrosucursal= lasucursal and tipofactura =eltipofactura and tipocomprobante = eltipocomprobante;
          elidusuario =  rcomproanulado.idusuario;
      ELSE 
         --Malapi 05-01-2015 Si hay que decrementa, verifico que si no existe el espacio, lo genero. IMPORTANTE: solo funciona cuando se desplaza un numero, en otros caso hay que eliminar los otros comprobantes a mano.    
         SELECT INTO rtemp * FROM facturaventa WHERE nrofactura =(elnrofactura + $5) and nrosucursal= lasucursal and tipofactura =eltipofactura
                  and tipocomprobante = eltipocomprobante;
         IF FOUND THEN 
                   --select into respuestaeliminar * from far_eliminarcomprobantenoemitido((elnrofactura + $5),lasucursal,eltipocomprobante,eltipofactura);
         END IF; 
      END IF;
      WHILE (desde <= hasta ) LOOP

            UPDATE facturaventa
            SET nrofactura = (elnrofactura + $5 )
            WHERE nrofactura =elnrofactura and nrosucursal= lasucursal and tipofactura =eltipofactura
                  and tipocomprobante = eltipocomprobante;

            /*UPDATE far_ordenventaitemitemfacturaventa
            SET nrofactura = (elnrofactura + $5)
            WHERE nrofactura =elnrofactura and nrosucursal=lasucursal and tipofactura = eltipofactura
                  and tipocomprobante = eltipocomprobante;*/

             IF (desplazamiento <0 ) THEN
                     elnrofactura = elnrofactura  + 1;
             ELSE
                     elnrofactura = elnrofactura  - 1;
             END IF;

             desde = desde +1 ;
      END LOOP;


IF false and elcomprobanteanulado <> 0 THEN 
--Malapi 05-01-2015 Si existe un espacio vacio, entonces genero el comprobante anulado. 

SELECT INTO rtemp * FROM facturaventa WHERE nrofactura =elcomprobanteanulado and nrosucursal= lasucursal and tipofactura =eltipofactura and tipocomprobante = eltipocomprobante;
         IF NOT FOUND THEN 
          --Se inserta la factura anulada 
                  INSERT INTO facturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,anulada,centro,fechaemision)
		  VALUES(eltipocomprobante,lasucursal,elcomprobanteanulado,eltipofactura, rcomproanulado.fechaemision,centro(),rcomproanulado.fechaemision);
                 -- Se guarda la informacion del usuario que genero el comprobante 
                 INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                 VALUES   (eltipocomprobante,lasucursal,elcomprobanteanulado, eltipofactura,elidusuario,elcomprobanteanulado);
        END IF;


END IF;


      --Se actualiza el talonario                            >0
     UPDATE talonario SET sgtenumero = (elmayor + ($5 +1 ))
     WHERE   nrosucursal=lasucursal and tipofactura = eltipofactura and tipocomprobante = eltipocomprobante ;


return 'true';
END;
$function$
