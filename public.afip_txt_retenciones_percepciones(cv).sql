CREATE OR REPLACE FUNCTION public.afip_txt_retenciones_percepciones(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Funcion que realiza la imputación  entre deudas y pagos
*/
DECLARE
       cursor_iva_comp refcursor;
       r_iva_comp RECORD;
       cant integer;
       rdata record;
BEGIN
     
     EXECUTE sys_dar_filtros($1) INTO rdata;


     -- 1 - Elimino los  registros generados para esa liquidacion iva
     DELETE  FROM afip_731_810 WHERE  idperiodofiscal = rdata.idperiodofiscal;


     --- (MTG 240719)  REGIMEN     PERCEPCIONES DE IVA: 393 (Empresas Proveedoras)
     --- (MTG 240719)  RETENCIONES DE IVA: 264 (que es de tarjetas de crédito que es lo único que estamos teniendo ahorita
     
     cant = 0;  
     PERFORM libroiva_compras_contemporal($1);
     
     OPEN cursor_iva_comp FOR 
               SELECT CASE WHEN rdata.retiva THEN retiva ELSE percepcionesiva END as elimporte
                      , CASE WHEN rdata.retiva THEN 'RETENCION' ELSE 'PERCEPCION' END as tipo
                      , CASE WHEN rdata.retiva THEN 264 ELSE 493 END as regimen
                      , *
               FROM temp_libroiva_compras_contemporal
               WHERE ((retiva > 0 or retiva<0) AND rdata.retiva) or ((percepcionesiva > 0 or percepcionesiva < 0) AND rdata.percepcionesiva);

     FETCH cursor_iva_comp INTO r_iva_comp;
     WHILE FOUND LOOP
            
        
       
           INSERT INTO afip_731_810(idperiodofiscal,tipo, regimen, cuit_agente, fecha_retencion, numero_comprobante,importe_retencion)
           VALUES( rdata.idperiodofiscal , r_iva_comp.tipo
                   , r_iva_comp.regimen
                   , rpad(replace(r_iva_comp.cuit,'-','') ,11,'@')                                 -- stringlong = 13 alineado = izquierda
                   , TO_CHAR(r_iva_comp.fechaemision :: DATE, 'dd/mm/yyyy')    -- formato DD/MM/AAAA
                   , CASE WHEN r_iva_comp.tipofactura='NCR' THEN rpad(concat('0',r_iva_comp.comprobante),14,'0')
                                                ELSE rpad(replace(r_iva_comp.comprobante,'-','' )::numeric,16,'0') END

/*Dani omento el 19062020*/             
      /*, rpad(replace(r_iva_comp.elcomprobante,' 000','' ),16,'@')                                        --  string long=16 alineado = izquierda*/
                   , lpad(round(r_iva_comp.elimporte::numeric,2) ,16,'@')                                            -- decimal long = 16 alineado = derecha
                    
           );
           
           FETCH cursor_iva_comp INTO r_iva_comp;
           cant = cant + 1;
     END LOOP;

     CLOSE cursor_iva_comp;


RETURN cant;
END;
$function$
