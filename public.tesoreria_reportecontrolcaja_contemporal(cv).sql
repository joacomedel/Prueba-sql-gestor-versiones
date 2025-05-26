CREATE OR REPLACE FUNCTION public.tesoreria_reportecontrolcaja_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;
  relem RECORD;
  rvalorescaja RECORD;
  vquery text;
  respuesta varchar;
  cursorcc refcursor;
  varrvalorescaja  varchar[];
  varrlongitud integer;
  vvalorescaja  varchar;
  vcontador integer;
BEGIN
 respuesta = '';
 EXECUTE sys_dar_filtros($1) INTO rparam;  
 
 

IF iftableexists('temp_tesoreria_reportecontrolcaja_contemporal') THEN
     DROP TABLE IF EXISTS temp_tesoreria_reportecontrolcaja_contemporal;
ELSE 
  
   CREATE TEMP TABLE temp_tesoreria_reportecontrolcaja_contemporal AS (
   SELECT t.*
    
FROM (
 
SELECT concat(idcontrolcaja,'-', idcentrocontrolcaja ) as elidcontrolcaja,idcontrolcaja,idcentrocontrolcaja,
fv.fechaemision,denominacion as elafiliado, concat(nrocliente, '-', cliente.barra) as nrocliente,
case when (fv.tipofactura='NC' or fv.tipofactura='OT')  then -1*monto 
      when not nullvalue(anulada) then 0.0 else monto  end  as importe,idcontrolcajafacturaventa as idccc, ccfv.centro as idcentroccc,
concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0')) as comprobante,
text_concatenar(concat(orden.nroorden,'-',fo.centro,'|')) as nroorden,
text_concatenar(concat(orden.fechaemision,'|')) as fechaemisionorden , anulada,
text_concatenar(concat(login,'|'))  AS usuario, fvc.idvalorescaja, ccfecha as fechacaja
FROM controlcaja  NATURAL JOIN controlcajafacturaventa ccfv NATURAL JOIN facturaventa fv 
JOIN facturaventacupon as fvc USING (nrofactura,tipofactura,tipocomprobante,nrosucursal,centro)
JOIN tipocomprobanteventa t on (fv.tipocomprobante=t.idtipo)
left JOIN cliente on (nrodoc=nrocliente and fv.barra=cliente.barra) 
LEFT JOIN facturaorden as fo USING (nrofactura,tipofactura,tipocomprobante,nrosucursal,centro)
LEFT JOIN orden USING (nroorden,centro) LEFT JOIN ordenrecibo USING(nroorden,centro) LEFT JOIN  recibousuario USING(idrecibo,centro) LEFT JOIN usuario USING(idusuario)
 
GROUP BY fv.nrofactura,ccfv.idcontrolcajafacturaventa,ccfv.centro,comprobante,elidcontrolcaja,idcontrolcaja,fv.tipofactura,idcentrocontrolcaja,elafiliado,comprobante,fv.fechaemision,nrocliente,cliente.barra, anulada, fvc.idvalorescaja,monto  
 

UNION

SELECT 
concat( idcontrolcaja,'-', idcentrocontrolcaja ) as elidcontrolcaja,
idcontrolcaja, idcentrocontrolcaja, fecharecibo AS fechaemision,  concat(p.apellido, ' ', p.nombres) as elafiliado, 
concat(CASE when not nullvalue(ccp.nrodoc) then ccp.nrodoc
      when not nullvalue(pa.nrodoc) then pa.nrodoc
      when not nullvalue(ccpc.idpago) then clientectacte.nrocliente
      ELSE '0'  END ,'-', p.barra) as nrocliente,
monto as importe,idcontrolcajarecibo as idccc,ccr.idcentrocontrolcajarecibo idcentroccc,
concat( idrecibo,'-',r.centro) as comprobante,
imputacionrecibo as nroorden,
null,  reanulado as anulada,login AS usuario, recibocupon.idvalorescaja, ccfecha as fechacaja

FROM controlcaja NATURAL JOIN controlcajarecibo ccr
NATURAL JOIN recibo r JOIN recibocupon USING (idrecibo, centro) NATURAL  JOIN recibousuario  JOIN usuario USING(idusuario)
LEFT JOIN cuentacorrientepagos as ccp ON (r.idrecibo = ccp.idcomprobante AND r.centro=ccp.idcentropago AND ccp.idcomprobantetipos = 0)
LEFT JOIN ctactepagocliente as ccpc ON (r.idrecibo = ccpc.idcomprobante AND r.centro=ccpc.idcentropago AND ccpc.idcomprobantetipos = 0)
LEFT JOIN clientectacte using(idclientectacte, idcentroclientectacte) 
LEFT JOIN persona p ON (case when nullvalue(ccpc.idclientectacte) then p.nrodoc=ccp.nrodoc else p.nrodoc=clientectacte.nrocliente end)
LEFT JOIN (select distinct on(idrecibo,centro) idrecibo,centro,idpagos from pagos)	as pagos USING(idrecibo,centro)
LEFT JOIN pagosafiliado as pa ON pagos.idpagos = pa.idpagos AND pagos.centro = pa.centro
          ) as t 

   WHERE idcontrolcaja = rparam.idcontrolcaja and  idcentrocontrolcaja = rparam.idcentrocontrolcaja 
   ORDER BY comprobante
       );

/*Genero dinamicamente las columnas de valores caja, tantas columnas como valores caja hubieron en los comprobantes incluidas en la misma*/
  SELECT INTO varrvalorescaja  (array_agg(concat( 'ALTER TABLE temp_tesoreria_reportecontrolcaja_contemporal  ADD COLUMN ', columna ,'  text') 
   order by idvalorescaja) )
			FROM  (
			SELECT concat('col_',idvalorescaja)  as columna , descripcion,idvalorescaja
			FROM 
      (
       SELECT  idvalorescaja, descripcion,idcontrolcaja ,idcentrocontrolcaja 
       FROM controlcaja  NATURAL JOIN controlcajafacturaventa ccfv 
       JOIN facturaventacupon as fvc USING (nrofactura,tipofactura,tipocomprobante,nrosucursal,centro) JOIN valorescaja as vc USING (idvalorescaja)
       GROUP BY  idvalorescaja, descripcion,idcontrolcaja ,idcentrocontrolcaja
       UNION 
       SELECT  idvalorescaja, descripcion,idcontrolcaja ,idcentrocontrolcaja 
       FROM controlcaja  NATURAL JOIN controlcajarecibo ccr NATURAL JOIN recibocupon as rc JOIN valorescaja as vc USING (idvalorescaja) 
       GROUP BY  idvalorescaja, descripcion,idcontrolcaja ,idcentrocontrolcaja
    ) AS T
    WHERE idcontrolcaja = rparam.idcontrolcaja and  idcentrocontrolcaja = rparam.idcentrocontrolcaja
   ORDER BY idvalorescaja
              ) x;

  SELECT INTO vquery  array_to_string(varrvalorescaja  , '; ' );
  SELECT INTO varrlongitud  array_length (varrvalorescaja  , 1 );

  EXECUTE vquery  ;	

/*Genero las columnas de valores caja para colocar en la columna que usamos para ordenar el excel en columnas */
  vcontador =11;
  FOR rvalorescaja  IN ( SELECT lower(replace(replace(replace(replace(replace(replace(descripcion,'.',''),'-','_'),')',''),'(',''),'/','_'),' ','')) as columna, 
 lower(replace(replace(replace(replace(replace(replace(descripcion,'.',''),'-','_'),')',''),'(',''),'/','_'),' ','')) as clave  
     FROM temp_tesoreria_reportecontrolcaja_contemporal  natural join valorescaja
     GROUP BY descripcion) 
     
     LOOP
       -- RAISE NOTICE 'rvalorescaja (% )',rvalorescaja   ;
        vcontador = vcontador +1;
        vvalorescaja  = concat(vvalorescaja  , '@',vcontador , '-', rvalorescaja.columna, '#',rvalorescaja.clave,'[+]');
    END LOOP;
 
  

  OPEN cursorcc FOR select * from temp_tesoreria_reportecontrolcaja_contemporal ;
  FETCH cursorcc  into relem;
  WHILE  found LOOP
	vquery = concat('UPDATE  temp_tesoreria_reportecontrolcaja_contemporal SET col_',relem.idvalorescaja,' =',
        round(CAST( relem.importe AS numeric),2)  ,'        
        WHERE temp_tesoreria_reportecontrolcaja_contemporal.idccc = ', relem.idccc ,' and  temp_tesoreria_reportecontrolcaja_contemporal.idcentroccc=',relem.idcentroccc , ' AND idvalorescaja= ',relem.idvalorescaja );
        EXECUTE vquery;
	FETCH cursorcc INTO relem;
   END LOOP;
   CLOSE cursorcc;

    


/*Renombro las columnas*/
  SELECT INTO vquery array_to_string(array_agg(concat( 'ALTER TABLE temp_tesoreria_reportecontrolcaja_contemporal RENAME COLUMN 
col_', split_part(columna , '|',1),' TO ', 
replace(replace(replace(replace(replace(replace(split_part(columna , '|',2),'.',''),'-','_'),')',''),'(',''),'/','_'),' ','') ) 
    
   order by idvalorescaja), '; ' )
			FROM  (
			SELECT DISTINCT idvalorescaja, concat(idvalorescaja,'|',replace(descripcion,' ','')) as columna 
			FROM temp_tesoreria_reportecontrolcaja_contemporal natural join valorescaja
            ORDER BY idvalorescaja
              ) x;
  EXECUTE vquery; 

	 
    vquery = 'ALTER TABLE temp_tesoreria_reportecontrolcaja_contemporal ADD COLUMN mapeocampocolumna text, ADD COLUMN fondocambio text ';
    EXECUTE vquery; 

    UPDATE temp_tesoreria_reportecontrolcaja_contemporal SET mapeocampocolumna = CONCAT('1-F.Emision#fechaemision@2-Afiliado#elafiliado@3-Nro.Cliente#nrocliente@4-Comprobante#comprobante@5-NroOrden#nroorden@6-Usuario#usuario@7-F. Emision Orden#fechaemisionorden@8-Control.Caja#elidcontrolcaja@9-Fecha Caja#fechacaja@10-Anulada#anulada@11-Fondo Cambio#fondocambio', vvalorescaja ), fondocambio = (SELECT sum(ccdtotal) as efectivo FROM public.controlcajadinero 
                                                  where idcontrolcaja= rparam.idcontrolcaja and  idcentrocontrolcaja = rparam.idcentrocontrolcaja) ;
 
    
  END IF;  
--por ahora ponemos esto. 
  respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
