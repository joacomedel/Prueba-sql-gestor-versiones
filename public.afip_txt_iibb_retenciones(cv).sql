CREATE OR REPLACE FUNCTION public.afip_txt_iibb_retenciones(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Funcion que realiza la imputación  entre deudas y pagos
*/
DECLARE
       cursor_comp refcursor;
       cursor_periibb refcursor;
       r_periibb RECORD;
       r_comp RECORD;
       cant integer;
       rdata record;
       elcomprobante RECORD;
       elnumeroregistro bigint;   
       elanio integer;
BEGIN


     --(*) F – Factura, R – Recibo, D - Nota de Débito, C - Nota de Crédito, O – Otros, E - Factura Electrónica, H - Notas de Crédito Electrónica, I - Notas de Débito Electrónica
     EXECUTE sys_dar_filtros($1) INTO rdata;


     -- 1 - Marco  los  registros ya generados para esa liquidacion iva
     -- RECORDAR QUE LAS LINEAS GENERADAS SON LAS nullvalue(fechaactivo) 
     UPDATE afip_iibb_retencion SET fechaactivo = now()  
     WHERE  idperiodofiscal = rdata.idperiodofiscal 
	    and nullvalue(fechaactivo);


     cant = 0;
     PERFORM libroiva_compras_contemporal($1);

     OPEN cursor_comp FOR
               SELECT  *
               FROM temp_libroiva_compras_contemporal
             --  WHERE  numregistro ilike '%165312%';
              ;
     FETCH cursor_comp INTO r_comp;
     WHILE FOUND LOOP
                     elnumeroregistro = split_part(r_comp.numregistro,'-' ,1);   
                     elanio =split_part(r_comp.numregistro,'-' ,2);   
                     -- busco informacion del comprobante
                      RAISE NOTICE ' reg (%)  anio (%)',elnumeroregistro,elanio;
                    
                     OPEN cursor_periibb FOR 
                              SELECT  *
                              FROM (  
                                      (SELECT numeroregistro, anio , '915' as jcodigo,pcuit,fechaemision,puntodeventa,numero
                                           , CASE WHEN (tipofactura='FAE') THEN 'E'
                                            WHEN (tipofactura='NDB') THEN 'D'
                                            WHEN (tipofactura='FAC') THEN 'F'
                                            WHEN (tipofactura='NCR') THEN 'C'
                                            ELSE 'O'
                                            END as eltipofactura
                                           ,letra , rlfpiibbneuquen	 as iibb_ret_importe 
                                     FROM  reclibrofact  
                                     NATURAL JOIN prestador
                                     WHERE numeroregistro = elnumeroregistro and reclibrofact.anio = elanio 
                                           AND ( not nullvalue(rlfpiibbneuquen	) and rlfpiibbneuquen	> 0 ) 
                                           AND (idprestador = 6297 and tipofactura = 'LIQ' and letra ='M' )  
                             )UNION(   
                                    SELECT numeroregistro, anio , '916' as jcodigo, pcuit,fechaemision,puntodeventa,numero
                                           , CASE WHEN (tipofactura='FAE') THEN 'E'
                                            WHEN (tipofactura='NDB') THEN 'D'
                                            WHEN (tipofactura='FAC') THEN 'F'
                                            WHEN (tipofactura='NCR') THEN 'C'
                                            ELSE 'O'
                                            END as eltipofactura
                                           , letra,rlfpiibbrionegro as iibb_ret_importe 
                                        
                                    FROM  reclibrofact 
                                    NATURAL JOIN prestador  
                                    WHERE numeroregistro = elnumeroregistro and reclibrofact.anio = elanio 
                                          AND ( not nullvalue(rlfpiibbrionegro) and rlfpiibbrionegro > 0 )
                                          AND (idprestador = 6297 and tipofactura = 'LIQ' and letra ='M' ) 
                         )
                      ) as T;
                     

		     
                     FETCH cursor_periibb INTO r_periibb;
                     WHILE FOUND LOOP

                                INSERT INTO afip_iibb_retencion(numeroregistro,anio, idperiodofiscal, cod_jurisdiccion, cuit_agente_percepcion, fecha_percepcion, sucursal, numero_constancia, tipo_comprobante, letra_Comprobante,numcomporiginal, importe_percibido 
                                 )VALUES( r_periibb.numeroregistro,
                                          r_periibb.anio,
                                          rdata.idperiodofiscal , 
                                          r_periibb.jcodigo,               --- Código de Jurisdicción Numérico de 3.[901,924]
                                          r_periibb.pcuit,                  -- Formato:20-­22222222­-3
                                          TO_CHAR(r_periibb.fechaemision:: DATE, 'dd/mm/yyyy') ,           -- dd/mm/aaaa
                                          lpad(r_periibb.puntodeventa,4,'@'),           -- Num. long 4
                                          lpad(r_periibb.numero,16,'0'),                 -- Completar con ceros a izquierda
                                          r_periibb.eltipofactura,            -- Texto 1
                                          r_periibb.letra,                  -- Texto 1
                                          rpad('0',20,'0'),
                                          lpad(round (r_periibb.iibb_ret_importe::numeric,2) ,11,'0')       -- numerico 11
                                   );

                         FETCH cursor_periibb INTO r_periibb;
                         END LOOP;
                         CLOSE cursor_periibb ;

           FETCH cursor_comp INTO r_comp;
           cant = cant + 1;
     END LOOP;

     CLOSE cursor_comp;


RETURN cant;
END;
$function$
