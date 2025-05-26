CREATE OR REPLACE FUNCTION public.tesoreria_reportecontrolcaja_resumen_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/*
SELECT * FROM tesoreria_reportecontrolcaja_resumen_contemporal('{idcentrocontrolcaja=1, idcontrolcaja=22}');
SELECT * FROM temp_tesoreria_reportecontrolcaja_resumen_contemporal 
*/
DECLARE
  rparam RECORD;
  rvalorescaja RECORD;
  colfpt text;
  vquery text;
  respuesta varchar;
  cursorcc refcursor;
  vfechacaja date;
  vcontador integer;
  vvalorescaja  varchar;
BEGIN
 respuesta = '';
 EXECUTE sys_dar_filtros($1) INTO rparam;  
 
 select into vfechacaja ccfecha from controlcaja where idcontrolcaja =  rparam.idcontrolcaja  and  idcentrocontrolcaja = rparam.idcentrocontrolcaja;

 SELECT INTO colfpt array_to_string(array_agg(concat( columna ,'  text' ) 
   order by idformapagotipos ), ', ' )
			FROM  (
			SELECT replace(replace(fpabreviatura,'.',''),' ','') as columna ,idformapagotipos 
			FROM 
      (
       SELECT idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja
       FROM controlcaja  NATURAL JOIN controlcajafacturaventa ccfv 
       JOIN facturaventacupon as fvc USING (nrofactura,tipofactura,tipocomprobante,nrosucursal,centro) JOIN valorescaja as vc USING (idvalorescaja) join formapagotipos using (idformapagotipos)
       GROUP BY  idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja
       UNION 
       SELECT idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja
       FROM controlcaja  NATURAL JOIN controlcajarecibo ccr NATURAL JOIN recibocupon as rc JOIN valorescaja as vc USING (idvalorescaja) join formapagotipos using (idformapagotipos)
       GROUP BY idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja
    ) AS T
    WHERE idcontrolcaja =  rparam.idcontrolcaja and  idcentrocontrolcaja = rparam.idcentrocontrolcaja 
 ORDER BY idformapagotipos 
              ) x;


   SELECT INTO vquery concat('CREATE TEMP TABLE temp_tesoreria_reportecontrolcaja_resumen_contemporal AS (select * from crosstab (
 ''select concat(mcf.nrocuentac,'''' - '''', vc.descripcion) as ctacble , replace(replace(fpabreviatura,''''.'''',''''''''),'''' '''','''''''')::text, round(CAST(sum(monto) AS numeric),2) 
   from 
   (SELECT idvalorescaja, case when ((fvc.tipofactura=''''NC'''' or fvc.tipofactura=''''OT'''') and  nullvalue(anulada)) then -1*monto when not nullvalue(anulada) then 0.0 else monto end monto,fvc.nrosucursal,idcontrolcaja ,idcentrocontrolcaja ,ccfecha , anulada
   FROM controlcaja  NATURAL JOIN controlcajafacturaventa ccfv NATURAL JOIN facturaventa
   JOIN facturaventacupon as fvc USING (nrofactura,tipofactura,tipocomprobante,nrosucursal,centro)
   UNION  ALL
   SELECT idvalorescaja, monto, nrosucursal ,idcontrolcaja ,idcentrocontrolcaja ,ccfecha, reanulado as anulada
   FROM controlcaja  NATURAL JOIN controlcajarecibo ccr NATURAL JOIN recibo NATURAL JOIN recibocupon as rc join  (select centro,nrosucursal
                 from talonario NATURAL JOIN (
                     SELECT max(talonariocc) as talonariocc,centro
                     FROM public.talonario where tipofactura = ''''FA''''  and tipocomprobante = 1 
                     group by centro
                     order by centro
                     ) as t ) AS ta using(centro)
   ) as tt
   
   JOIN valorescaja as vc USING (idvalorescaja) NATURAL JOIN formapagotipos as fpt 
   JOIN multivac.formapagotiposcuentafondos fptcf ON(fptcf.idvalorescaja=tt.idvalorescaja and fptcf.nrosucursal=tt.nrosucursal ) 
   natural join multivac.mapeocuentasfondos mcf
   WHERE idcontrolcaja = ', rparam.idcontrolcaja ,' and  idcentrocontrolcaja =', rparam.idcentrocontrolcaja,'
   group by  mcf.nrocuentac, vc.descripcion, fpabreviatura, ccfecha
  
   ORDER  BY 1'',
 ''select replace(replace(fpabreviatura,''''.'''',''''''''),'''' '''','''''''') from (
       SELECT idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja 
       FROM controlcaja  NATURAL JOIN controlcajafacturaventa ccfv 
       JOIN facturaventacupon as fvc USING (nrofactura,tipofactura,tipocomprobante,nrosucursal,centro) JOIN valorescaja as vc USING (idvalorescaja) join formapagotipos using (idformapagotipos)
       GROUP BY  idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja
       UNION 
       SELECT idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja 
       FROM controlcaja  NATURAL JOIN controlcajarecibo ccr NATURAL JOIN recibocupon as rc JOIN valorescaja as vc USING (idvalorescaja) join formapagotipos using (idformapagotipos)
       GROUP BY idformapagotipos, fpabreviatura,idcontrolcaja ,idcentrocontrolcaja
    ) AS T
    WHERE idcontrolcaja = ', rparam.idcontrolcaja ,' and  idcentrocontrolcaja =', rparam.idcentrocontrolcaja,' 
 ORDER BY idformapagotipos  ''
 )
 as t( 
  ctacble text,',colfpt ,' ))'
 ); 

   RAISE NOTICE 'vquery(%)',vquery;
  EXECUTE vquery;	

  
  vcontador =1;
  FOR rvalorescaja  IN ( 
select column_name  from information_schema.columns where table_name = 'temp_tesoreria_reportecontrolcaja_resumen_contemporal') 
     
     LOOP
       -- RAISE NOTICE 'rvalorescaja (% )',rvalorescaja   ;       
        vcontador = vcontador +1; 
        --KR 28-10-21 el totalizador va solo para las columnas con importes, desde la 3 en adelante. 
        vvalorescaja  = case when vcontador <= 2 then  concat(vvalorescaja  , '@',vcontador , '-', rvalorescaja.column_name , '#',rvalorescaja.column_name) else concat(vvalorescaja  , '@',vcontador , '-', rvalorescaja.column_name , '#',rvalorescaja.column_name,'[+]') end;
     
    END LOOP;
 
  
  vquery = 'ALTER TABLE temp_tesoreria_reportecontrolcaja_resumen_contemporal ADD COLUMN mapeocampocolumna text; 
            ALTER TABLE temp_tesoreria_reportecontrolcaja_resumen_contemporal ADD COLUMN fechacaja date;   ';
  EXECUTE vquery; 

  UPDATE temp_tesoreria_reportecontrolcaja_resumen_contemporal SET fechacaja=vfechacaja , mapeocampocolumna = CONCAT('1-F.Caja#fechacaja', vvalorescaja ) ;
 
--por ahora ponemos esto. 
  respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
