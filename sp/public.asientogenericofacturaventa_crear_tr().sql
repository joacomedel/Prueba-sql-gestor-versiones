CREATE OR REPLACE FUNCTION public.asientogenericofacturaventa_crear_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
--record
  rgeneracontabilidad RECORD; 
  rasientogenerico RECORD; 
  rasiento_nuevo numeric;
  xidasiento bigint;
  elidasientogenerico bigint;
        elidcentroasientogenerico integer;
  esnecesariogenerarcontabilidad boolean;
BEGIN

-- MaLaPi 16-05-2022 para no repetir el codigo uso una bandera
esnecesariogenerarcontabilidad = false;

-- pidoperacion formato: 'FA|1|20|1894'	
--MaLaPi 21-02-2019 No se genera mas la contabilidad para la sucursal 19 de Farmacia.
--KR 12-06-19 Toma la tabla de parametros para saber si debe generar contabilidad o no
SELECT INTO rgeneracontabilidad *  
      FROM contabilidadoffline
      WHERE  cotipo= 'facturaventa' AND conrosucursal = NEW.nrosucursal AND nullvalue(cofechahasta);
      IF NOT FOUND THEN  -- no es una sucursal configurada como fuera de linea
       RAISE NOTICE '>>>>>>>>>>>>>>> TG_OP (%)',TG_OP ;
        esnecesariogenerarcontabilidad = true;
      END IF;

      SELECT INTO rasientogenerico *
               FROM asientogenerico 
               WHERE idcomprobantesiges =  concat(NEW.tipofactura,'|',NEW.tipocomprobante,'|',NEW.nrosucursal,'|',NEW.nrofactura);
       IF FOUND THEN  -- Si el comprobante ya genero contabilidad, se debe modificar, no importa como este configurada la sucursal
           esnecesariogenerarcontabilidad = true;
       END IF;
       
       IF esnecesariogenerarcontabilidad THEN 
        --El SP crear verifica si hay que modificar o no la contabilidad
          perform asientogenericofacturaventa_crear(concat(NEW.tipofactura,'|',NEW.tipocomprobante,'|',NEW.nrosucursal,'|',NEW.nrofactura));

       END IF;  -- Fin de IF esnecesariogenerarcontabilidad THEN 

  /*Dani 15-01-2020 agrego control para que cuando algun importe de la cabecera quedo nulo, le   ponga cero*/

UPDATE facturaventa SET importeamuc = CASE WHEN nullvalue(importeamuc) THEN 0 ELSE importeamuc END,
importeefectivo = CASE WHEN nullvalue(importeefectivo) THEN 0 ELSE importeefectivo END,
importedebito = CASE WHEN nullvalue(importedebito) THEN 0 ELSE importedebito END,
importecredito = CASE WHEN nullvalue(importecredito) THEN 0 ELSE importecredito END,
importectacte = CASE WHEN nullvalue(importectacte) THEN 0 ELSE importectacte END,
importesosunc = CASE WHEN nullvalue(importesosunc) THEN 0 ELSE importesosunc END
WHERE  
tipofactura=NEW.tipofactura
and tipocomprobante=NEW.tipocomprobante
and nrosucursal=NEW.nrosucursal
and nrofactura=NEW.nrofactura
AND  (nullvalue(importeamuc) OR nullvalue(importeefectivo) OR nullvalue(importedebito) or nullvalue(importecredito) or nullvalue(importectacte) OR nullvalue(importesosunc));

return NEW;

END;
$function$
