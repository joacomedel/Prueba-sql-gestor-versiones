CREATE OR REPLACE FUNCTION public.calcularplandepago(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de prestaciones.*/

DECLARE

--RECORD
  rfiltros RECORD;

--VARIABLES
  importecuotatotal DOUBLE PRECISION;
  desplazamiento INTEGER;
  indice INTEGER;
  impinteres  DOUBLE PRECISION;
  impivainteres DOUBLE PRECISION;

  ffinanciero  DOUBLE PRECISION;
  arancel  DOUBLE PRECISION;
BEGIN

  EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
  
  
  CREATE TEMP TABLE tempcuentacorrientedeuda (   
		tipodoc INTEGER  NOT NULL, 
                nrodoc VARCHAR NOT NULL,   
                importeanticipo float DEFAULT 0,  
                movconcepto VARCHAR, 
		idtempcuentacorrientedeuda INTEGER,
                importecuota FLOAT DEFAULT 0,
		importeinteres float DEFAULT 0,  
		importeivainteres float DEFAULT 0
--,
               -- importetotal float DEFAULT 0
 
		);
     
  
   IF rfiltros.importeanticipo <> 0 and rfiltros.planpago THEN
       -- Insercion de la info de la cuota
       INSERT INTO tempcuentacorrientedeuda (tipodoc,nrodoc, importeanticipo, movconcepto)
       VALUES( rfiltros.tipodoc,rfiltros.nrodoc,rfiltros.importeanticipo,  'Prestamo - Anticipo ');

   END IF;

   IF( rfiltros.planpago ) THEN
     FOR indice IN 1..rfiltros.cantidadcuotas LOOP        
        importecuotatotal = rfiltros.importecuotas;        
        INSERT INTO tempcuentacorrientedeuda (idtempcuentacorrientedeuda,tipodoc,nrodoc, importecuota, movconcepto)
        VALUES(indice, rfiltros.tipodoc,rfiltros.nrodoc,rfiltros.importecuotas, concat((case when  rfiltros.planpago then 'Prestamo - ' end), 'Importe Total Cuota Nº ',indice ));
        IF rfiltros.intereses <> 0 THEN
          desplazamiento =  indice -1;
          impinteres = round (cast(((rfiltros.cantidadcuotas - desplazamiento) * rfiltros.importecuotas * rfiltros.intereses) as numeric),4);
          impivainteres =  round((impinteres * 0.21)::numeric,4);   
          UPDATE tempcuentacorrientedeuda SET importeinteres = impinteres, importeivainteres = impivainteres                                                  
                       WHERE idtempcuentacorrientedeuda= indice; 
                   
         
        END IF;
      END LOOP;

  ELSE
    FOR indice IN 1..rfiltros.cantidadcuotas LOOP        
        importecuotatotal = rfiltros.importecuotas;        
        INSERT INTO tempcuentacorrientedeuda (idtempcuentacorrientedeuda,tipodoc,nrodoc, importecuota, movconcepto)
        VALUES(indice, rfiltros.tipodoc,rfiltros.nrodoc,rfiltros.importecuotas, concat((case when  rfiltros.planpago then 'Prestamo - ' end), 'Importe Total Cuota Nº ',indice ));
        IF rfiltros.arancel <> 0 THEN
          desplazamiento =  indice -1;
          ffinanciero = round (cast(( rfiltros.importecuotas * (rfiltros.ffinanciero)) as numeric),4);
          arancel =  round((ffinanciero * (rfiltros.arancel))::numeric,4);  
          ffinanciero = ffinanciero-rfiltros.importecuotas;

          UPDATE tempcuentacorrientedeuda SET importeinteres = arancel, importeivainteres = ffinanciero                                                  
                       WHERE idtempcuentacorrientedeuda= indice; 
               
     
      END IF;
    END LOOP;

  END IF;
  
RETURN true;
END;$function$
