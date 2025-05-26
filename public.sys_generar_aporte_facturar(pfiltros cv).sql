CREATE OR REPLACE FUNCTION public.sys_generar_aporte_facturar(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--VARIABLES
	vtodook varchar;
	vsefacturo varchar;
        informeF integer;
--CURSOR
        cursorac refcursor;	
--RECORD
        unatupla record;
        rexiste record;
        rfiltros record; 
BEGIN 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF rfiltros.accion = 'ingresarnovedades' THEN 

INSERT INTO temporal_jubilados (nombres, nroafiliado, tarea, periodo, importeaporte, iva, total, nrodoc, barra, importebruto, porcentaje, mesaporte, anioaporte, importeconiva, presentonota, incrementomasivo) (

SELECT nombres, nroafiliado, tarea, periodo, importeaporte, iva, total, nrodoc, barra, importebruto, porcentaje, mesaporte, anioaporte, importeconiva, presentonota, incrementomasivo  FROM temporal_jubilados_excel
) ;

END IF;

IF rfiltros.accion = 'aportemensual' THEN 

--Se Generar los aportes 
SELECT INTO vtodook * FROM sys_agregaraportesjubpen(pfiltros);
RAISE NOTICE 'Ya se Genero el aporte Mensual';

--Se facturan los aportes generados
--KR 29-06-21 Se facturan desde caja 
--SELECT INTO vsefacturo * FROM w_asentarcomprobantefacturacioninformes('');
--RAISE NOTICE 'Ya se Facturo el aporte Mensual';

END IF;

IF rfiltros.accion = 'novedades' THEN 

-- Se modifica el importe del aporte de las novedades
   IF rfiltros.tarea = 'corregirimportefacturar' OR rfiltros.tarea ilike 'aportenuevo'  THEN
      SELECT INTO vtodook * FROM generarimporteaportes('');   

   END IF;

-- Se modifica el importe del aporte de las novedades
   IF rfiltros.tarea = 'baja' THEN
     --DOY DE BAJA los aportes que asi se solicitan
    UPDATE aporteconfiguracion SET acfechafin=now(),descripcion=CONCAT(descripcion, 'Presento nota:', T.presentonota,'OBS: ',T.observaciones) 
    FROM (select *   from  temporal_jubilados where nullvalue(fechauso) AND ( trim(tarea) ilike '%baja%')) AS T
    WHERE aporteconfiguracion.nrodoc=T.nrodoc AND  nullvalue(acfechafin);
      
    UPDATE temporal_jubilados SET fechauso = now() where nullvalue(fechauso) AND trim(tarea) ilike '%baja%';

   END IF;

   -- Se modifica el importe del aporte de las novedades
   IF rfiltros.tarea = 'modificaimportemasivo' THEN
      SELECT INTO vtodook * FROM generarimporteaportes_masivo('{ accion=procesaincremento, incremento= ' || rfiltros.incremento|| ' }');   

   END IF;

   -- Se COBRA un retroactivo de las novedades
   IF rfiltros.tarea ilike 'RETROACTIVO' THEN      
     SELECT INTO vtodook * FROM sys_agregaraportesjubpen(pfiltros);
      --update las tareas que ya hice con la fecha uso hoy
    UPDATE temporal_jubilados SET fechauso = now() where nullvalue(fechauso) AND tarea ilike concat('%',rfiltros.tarea,'%');

   END IF;

-- Se generan los pendientes las Notas de Credito y Facturas
   IF rfiltros.tarea ilike 'FA Emitir' OR rfiltros.tarea ilike 'NC Emitir' THEN  

    CREATE TEMP TABLE temp_aporteconfiguracion_nc (idaporte,idcentroregionaluso,tipofactura,nrodoc,tipodoc,importesiniva,importeiva,importetotal) AS (
     SELECT min(idaporte) as idaporte,idcentroregionaluso,trim(upper(split_part(rfiltros.tarea,' ',1)))::text as tipofactura,nrodoc,tipodoc,round((importeconiva/1.105)::numeric,2)  
        importesiniva,round(((importeconiva/1.105)*0.105)::numeric,2) as importeiva,importeconiva as importetotal
    FROM public.temporal_jubilados JOIN aporteconfiguracion USING(nrodoc) JOIN aporteconfiguracioninformefacturacion USING(idcentroaporteconfiguracion,idaporteconfiguracion)
JOIN informefacturacionaporte USING(nroinforme,idcentroinformefacturacion) 
--MaLaPi 11-08-2021 agrego and acifanioaporte = anioaporte porque el mes de Julio del 2021 selecciono mal el idaporte, seleccionando el aporte de Julio de 2021
  WHERE tarea ilike concat('%',rfiltros.tarea,'%') AND acifmesaporte = mesaporte and acifanioaporte = anioaporte AND acfechainicio >= '2020-05-01' and nullvalue(fechauso)   
  group by mesaporte,idcentroregionaluso, nrodoc,tipodoc,importeconiva
  order by nrodoc
  
  );
      OPEN cursorac FOR SELECT * FROM temp_aporteconfiguracion_nc;
      FETCH cursorac INTO unatupla;
      WHILE FOUND LOOP
        SELECT INTO informeF * FROM crearinformefacturacion( unatupla.nrodoc, cast(unatupla.tipodoc as integer), 6);
        UPDATE informefacturacion SET idtipofactura = unatupla.tipofactura WHERE nroinforme=informeF AND idcentroinformefacturacion = centro();
        INSERT INTO  informefacturacionaporte(nroinforme,idcentroinformefacturacion,idaporte,idcentroregionaluso)
                  VALUES(informeF,centro(), unatupla.idaporte, unatupla.idcentroregionaluso);
        SELECT INTO rexiste * FROM aporte where idaporte = unatupla.idaporte AND idcentroregionaluso = unatupla.idcentroregionaluso;
        INSERT INTO informefacturacionitem(idcentroinformefacturacionitem,idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion,idiva)
        VALUES(centro(),centro(),informeF,'40245',1,unatupla.importetotal,concat('Corrección Aporte ',rexiste.mes,'-',rexiste.ano,' ',unatupla.tipofactura , ' Codigo aporte ' ,unatupla.idaporte, '-', unatupla.idcentroregionaluso),3);
       
        INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini)
             VALUES(informeF,centro(),3,NOW()); 
	 
      FETCH cursorac INTO unatupla;

     END LOOP;
     CLOSE cursorac;

  --update las tareas que ya hice con la fecha uso hoy
    UPDATE temporal_jubilados SET fechauso = now() where nullvalue(fechauso) AND tarea ilike concat('%',rfiltros.tarea,'%');

       

   END IF;
--Se facturan los aportes generados
--KR 22-06-21 COmento pq queremos determinar la sucursal desde el sistema
--SELECT INTO vsefacturo * FROM w_asentarcomprobantefacturacioninformes('');

RAISE NOTICE 'Ya se procesaron las novedades de (%)',rfiltros.tarea;
RAISE NOTICE 'Ya se procesaron las novedades';
END IF;
	
  

return vsefacturo;
END;
$function$
