CREATE OR REPLACE FUNCTION public.far_procesar_liquidacion(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*Dado un nroregistro y año asociado a un comprobante de liquidacion, lo procesa y genera toda la auditoria*/

    unafactura             RECORD;
    unpendiente            RECORD; 
    unpendienteaprocesar   RECORD;
    unrece                 RECORD;
    elemreci               RECORD;
    aux                    RECORD;
    aux2                   RECORD;
    creceliq               refcursor;
 
BEGIN

    /*Busca si el registro esta en estado prependiente (tipoestadofactura=0)*/	
    SELECT into unafactura factura.*  
           FROM factura NATURAL JOIN festados WHERE tipoestadofactura=0 AND nullvalue(fefechafin)
              AND idprestador=2608 AND nroregistro=$1 and anio=$2   AND idtipocomprobante=7    ORDER BY ffecharecepcion ;

  IF  FOUND THEN /*SI ENCONTRO REGISTRO EN ESTADO PREPENDIENTE*/
              
  /*Controla que tenga pendientes de auditoria para procesar y sino los genera*/
             SELECT into unpendiente   * FROM far_ordenventaliquidacionauditada 
		   WHERE  nroregistro=$1 and anio=$2    ORDER BY idordenventaliquidacionauditada; 
            IF  not FOUND THEN /*si no tenia pendientes de procesar los genera*/
             RAISE NOTICE '>>>>>>>>entro por el no tenia pendientes de procesar los genera';
              
              select into aux2 * from  far_generapendienteliquidacionauditoria($1,$2); 
    	
            END IF;  /*si tenia pendientes de procesar*/
   /*Procesa los pendientes encontrados/generados*/
    OPEN creceliq FOR  
	    SELECT    * FROM far_ordenventaliquidacionauditada    WHERE  nroregistro=$1 and anio=$2;  
               FETCH creceliq into unrece;
               WHILE  FOUND LOOP
                RAISE NOTICE '>>>>>>>>entro al while por el no tenia pendientes de procesar los genera (%)',unrece.idordenventaliquidacionauditada;
    	               select into aux * from  far_procesar_pendienteliquidacionauditoria(unrece.idordenventaliquidacionauditada);

               FETCH creceliq into unrece;
               end loop;
        close creceliq ;
   /*Al final llama al sp que procesa las recetas que eraan de reciprocidad*/
	 SELECT into elemreci  FROM far_procesaliquidacionordenreci($1,$2); 

    
ELSE /*SI ENCONTRO REGISTRO EN ESTADO PREPENDIENTE*/

END IF;/*SI ENCONTRO REGISTRO EN ESTADO PREPENDIENTE*/

return 	true;
END;$function$
