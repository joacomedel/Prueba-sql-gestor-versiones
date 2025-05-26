CREATE OR REPLACE FUNCTION public.controlfacturacion(date, date, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  nroanterior bigint;
  fechaanterior date;
  
  elmayor bigint;
  lanrosucursal integer;
  
  fdesde date;
  fhasta date;
  nrodesde bigint;
  nrohasta bigint;
  estacomp record;
  ctalonario refcursor;
  untalonario record;
  cfactura refcursor;
  unfac record;

BEGIN

IF NOT iftableexists('tempcontrolfacturacion') THEN
       CREATE TEMP TABLE tempcontrolfacturacion (
              "nrosucursal" INTEGER,
              "tipocomprobante" INTEGER,
              "tipofactura" VARCHAR,
              "desdenrofactura" BIGINT,
              "hastanrofactura" BIGINT,
              "logcontrol" VARCHAR(256),
              "tipocomprobantedesc" VARCHAR
       );
END IF;
     fdesde =$1 ;
     fhasta = $2 ;
     lanrosucursal = $3;
   --  nrohasta =$4 ;

     ------------------------------------------------
     ----- Busco los talonarios de la sucursal  -----
     ------------------------------------------------
    -- DELETE FROM tempcontrolfacturacion;
     OPEN ctalonario FOR SELECT * 
                   FROM talonario  
                   join tipocomprobanteventa ON (idtipo=tipocomprobante)
                   WHERE nrosucursal  = lanrosucursal  
                        AND (tipofactura = 'FA'  
                              or  tipofactura = 'NC'
                              or  tipofactura = 'ND' or tipofactura = 'TK')
                   ORDER BY descripcion;
     
     FETCH ctalonario into untalonario;
     WHILE FOUND LOOP
           ------------------------------------------------
           ------- Busco los comprobantes del talonario
           ------------------------------------------------
           OPEN cfactura FOR  SELECT *  FROM facturaventa  WHERE fechaemision >=fdesde and fechaemision <=fhasta
                and nrosucursal = lanrosucursal
                and tipocomprobante = untalonario.tipocomprobante and tipofactura=untalonario.tipofactura
                order by nrofactura;
           nroanterior =0;
           FETCH cfactura into unfac;
           WHILE (FOUND ) LOOP
                 if (nroanterior = 0)THEN
                     INSERT INTO tempcontrolfacturacion(nrosucursal,tipocomprobante,tipocomprobantedesc,tipofactura,desdenrofactura)
                     VALUES(unfac.nrosucursal,unfac.tipocomprobante, untalonario.desccomprobanteventa ,unfac.tipofactura,unfac.nrofactura);
                     fechaanterior = unfac.fechaemision;
                 END IF;
                  if(nroanterior <> 0 and  nroanterior <> unfac.nrofactura - 1 ) THEN
                      SELECT INTO estacomp * FROM facturaventa WHERE nrofactura = nroanterior + 1
                             and nrosucursal = lanrosucursal
                             and tipocomprobante = untalonario.tipocomprobante and tipofactura=untalonario.tipofactura;
                      IF FOUND THEN
                                 ------------ Notifico error en la fecha de emision
                                    INSERT INTO tempcontrolfacturacion(nrosucursal,tipocomprobante,tipocomprobantedesc,tipofactura,logcontrol)
                                    VALUES(unfac.nrosucursal,unfac.tipocomprobante, untalonario.desccomprobanteventa , unfac.tipofactura,
                                    concat('Fecha emisión no correlativa del comp: ',nroanterior + 1 , ' - ',to_char(estacomp.fechaemision,'dd/mm/yy ')) );

                      ELSE
                                    ------------ Notifico el hueco en la facturacion
                                    INSERT INTO tempcontrolfacturacion(nrosucursal,tipocomprobante,tipocomprobantedesc,tipofactura,logcontrol)
                                    VALUES(unfac.nrosucursal,unfac.tipocomprobante, untalonario.desccomprobanteventa , unfac.tipofactura,concat('Salto Numeración ',nroanterior , ' - ',unfac.nrofactura));
                      END IF;
                  END IF;
                  
                  
                  if( fechaanterior > unfac.fechaemision::date ) THEN
                      ------------ Notifico el hueco en la facturacion
                      INSERT INTO tempcontrolfacturacion(nrosucursal,tipocomprobante,tipocomprobantedesc,tipofactura,logcontrol)
                      VALUES(unfac.nrosucursal,unfac.tipocomprobante, untalonario.desccomprobanteventa , unfac.tipofactura,concat('Fecha emisión del comp.',nroanterior ,': ', to_char(fechaanterior,'dd/mm/yy '),'/// Fecha emisión del comp.' ,unfac.nrofactura ,' : ',to_char(unfac.fechaemision,'dd/mm/yy ')) );
                  END IF;

                  
                  
                  nroanterior = unfac.nrofactura;
                  fechaanterior = unfac.fechaemision;
                  FETCH cfactura into unfac;
           END LOOP;
           CLOSE cfactura;
           UPDATE tempcontrolfacturacion SET hastanrofactura = nroanterior
           WHERE nrosucursal = untalonario.nrosucursal AND  tipocomprobante= untalonario.tipocomprobante
           AND  tipofactura = untalonario.tipofactura;
         
     FETCH ctalonario into untalonario;
     END LOOP;
     
     CLOSE ctalonario;

return TRUE;
END;
$function$
