CREATE OR REPLACE FUNCTION public.sys_agregaraportesjubpen(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD       
runac RECORD;
ridiva RECORD;
rfiltros record; 

--CURSOR 
cursorac REFCURSOR;

--VARIABLES
vnroinforme BIGINT;

BEGIN
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF NOT iftableexists('tempaportejubpen') THEN
/*si la tabla no existe, no viene desde la aplicacion entonces, puedo insertar los datos que precise para llamar a los SP que generan los aportes. Osea, aqui falta el insert. */

   CREATE TEMP TABLE tempaportejubpen (
			nrodoc VARCHAR(8) NOT NULL,
			importe DOUBLE PRECISION NOT NULL, 
			mes SMALLINT NOT NULL,
			anio INTEGER NOT NULL,
			tipodoc SMALLINT, 
			idformapagotipos INTEGER,
			descripaporte VARCHAR 
			) WITHOUT OIDS;
/*si el mes o anio no son los actuales, guardamos alli los valores de mes y anio que queremos cobrar */
 IF rfiltros.accion = 'aportemensual' THEN 
   
   CREATE TEMP TABLE temp_aportejubpen AS 
     SELECT distinct idaporteconfiguracion,idcentroaporteconfiguracion ,false as generarecibo, case when date_part('day', current_date ) > 15 then date_part('month', current_date+20) else date_part('month', current_date) end mes, case when date_part('day', current_date ) > 15 then date_part('year', current_date+20) else date_part('year', current_date)  end anio, ac.nrodoc, acimporteaporte,tipodoc,3 as idformapagotipos, concat('Aporte Mensual Periodo:', case when date_part('day', current_date ) > 15 then date_part('month', current_date+30) else date_part('month', current_date) end, '-', case when date_part('day', current_date ) > 15 then date_part('year', current_date+30) else date_part('year', current_date)  end, '. GMA.')
     
        FROM aporteconfiguracion ac
         NATURAL JOIN persona 
         LEFT JOIN aporteconfiguracioninformefacturacion as acif USING(idaporteconfiguracion,idcentroaporteconfiguracion)
           WHERE  nullvalue(acfechafin) AND  (barra=35 or barra=36) and acfechainicio>='2020-05-01'
 -- and nrodoc='05948550'  ;
AND (nullvalue(acifmesaporte) OR acifmesaporte <> (case when date_part('day', current_date ) > 15 then date_part('month', current_date+30) else date_part('month', current_date) end))  ;
 END IF;
 IF rfiltros.tarea = 'RETROACTIVO' THEN 

 CREATE TEMP TABLE temp_aportejubpen AS 
         select idaporteconfiguracion,idcentroaporteconfiguracion ,false as generarecibo, mesaporte mes, anioaporte anio, ac.nrodoc,importeaporte acimporteaporte,tipodoc,3 as idformapagotipos, concat('Aporte Retroactivo Periodo:', mesaporte, '-', anioaporte, '. GMA.')
         FROM aporteconfiguracion ac JOIN  temporal_jubilados USING(nrodoc)          
         WHERE nullvalue(fechauso) and  nullvalue(acfechafin) and tarea ilike '%RETROACTIVO%';
 END IF;
ELSE 
   DELETE FROM tempaportejubpen;
END IF;


 OPEN cursorac FOR SELECT * FROM temp_aportejubpen;
 FETCH cursorac INTO runac;
 WHILE FOUND LOOP

      INSERT INTO tempaportejubpen (nrodoc,importe,mes,anio,tipodoc,idformapagotipos,descripaporte)
	VALUES (runac.nrodoc,runac.acimporteaporte ,runac.mes, runac.anio, runac.tipodoc, 3, 
       concat('Aporte Mensual Perido:',runac.mes, '-', runac.anio, '. GMA'));

      SELECT INTO vnroinforme * FROM agregaraportesjubpen('malapi');	
      INSERT INTO aporteconfiguracioninformefacturacion (idaporteconfiguracion,idcentroaporteconfiguracion,nroinforme,idcentroinformefacturacion,acifmesaporte,acifanioaporte) 
      VALUES(runac.idaporteconfiguracion,runac.idcentroaporteconfiguracion,vnroinforme,centro(),runac.mes,runac.anio); 
      
      UPDATE informefacturacion set idformapagotipos = 3 WHERE nroinforme =vnroinforme AND idcentroinformefacturacion = centro();
 
      DELETE FROM tempaportejubpen;

 FETCH cursorac INTO runac;

 END LOOP;
 CLOSE cursorac;

 
 --  UPDATE temporal_jubilados SET fechauso = now() where nullvalue(fechauso) AND tarea ilike '%RETROACTIVO%';
return '';
END;

$function$
