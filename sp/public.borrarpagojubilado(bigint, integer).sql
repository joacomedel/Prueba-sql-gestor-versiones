CREATE OR REPLACE FUNCTION public.borrarpagojubilado(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*select  * from borrarpagojubilado(nrorecibo,idcentrorecibo);*/

         elaportejubpen RECORD;
         elaporteuniversidad RECORD;
	 elaportesinfacturas RECORD;
	 elinformefacturacionaporte RECORD;
	 elinformefacturacionitem RECORD;
	 elinformefacturacionestado RECORD;
	 elinformefacturacion RECORD;
	 elimporterecibo RECORD;
	 elrecibousuario RECORD;
	 elrecibo RECORD;
         elem RECORD;
         lafactura RECORD;
         elcargo RECORD;
         elinforme RECORD;
         eleminformeaporte RECORD;
         eldatofactura RECORD;
         elaporte integer;
         temporal RECORD;
         losaportes cursor for
              select  * FROM aporte WHERE  idrecibo=$1 and idcentroregionaluso=$2;
BEGIN
      /*Revisar antes de usar que sea lo q realmente necesitamos...*/
   
OPEN losaportes;
FETCH losaportes INTO elem;
WHILE  found LOOP
          /*busco que el informe no este facturado*/
           select  into eldatofactura * 
           FROM aporte natural join informefacturacionaporte
           natural join informefacturacion    
           natural join informefacturacionestado WHERE  idaporte=elem.idaporte and 
           idcentroregionaluso=elem.idcentroregionaluso and  	idinformefacturacionestadotipo <>5 and
           nullvalue(fechafin);


          if (found ) then /*si encuentra un informe activo*/

                 select into lafactura * from informefacturacion 
                 natural join facturaventa
                 WHERE nroinforme=eldatofactura.nroinforme
                 and idcentroinformefacturacion=eldatofactura.idcentroinformefacturacion;

                if (found and  not  nullvalue(eldatofactura.nrofactura))then  
                    /*si el informe tiene asociada una factura*/
   
                     RAISE EXCEPTION 'NO ES POSIBLE ELIMINAR EL RECIBO POR QUE 
                                      ESTA FACURADO(%)',eldatofactura.nrofactura;
                     
                 else
                /* si el informe no tiene asociada una factura*/




                

                 select into elaportejubpen * FROM aportejubpen WHERE  idaporte=elem.idaporte and  
                 idcentroregionaluso=elem.idcentroregionaluso;
                 if found then 
                           delete from aportejubpen where idaporte=elem.idaporte and  
                           idcentroregionaluso=elem.idcentroregionaluso;
                           select into elaportesinfacturas * FROM aportessinfacturas 
                           WHERE  idaporte=elem.idaporte and    idcentroregionaluso=elem.idcentroregionaluso
                           and nrodoc=elaportejubpen.nrodoc and tipodoc=elaportejubpen.tipodoc and 
                           mes=elaportejubpen.mes and anio=elaportejubpen.anio;
                           if found then 
                                    delete from aportessinfacturas WHERE  idaporte=elem.idaporte 
                                    and idcentroregionaluso=elem.idcentroregionaluso
                                    and nrodoc=elaportejubpen.nrodoc and tipodoc=elaportejubpen.tipodoc
                                    and mes=elaportejubpen.mes and anio=elaportejubpen.anio;
                           end if;
                 else
 
                  select into elcargo * FROM cargo WHERE  idcargo=elem.idcargo;
                  if found then 
                        select into elaportesinfacturas * FROM aportessinfacturas 
                        WHERE  idaporte=elem.idaporte and    idcentroregionaluso=elem.idcentroregionaluso
                        and nrodoc=elcargo.nrodoc and tipodoc=elcargo.tipodoc and mes=elem.mes 
                        and anio=elem.ano;
                        if found then

                              delete from aportessinfacturas WHERE  idaporte=elem.idaporte 
                              and idcentroregionaluso=elem.idcentroregionaluso
                              and nrodoc=elcargo.nrodoc and tipodoc=elcargo.tipodoc 
                              and mes=elem.mes and anio=elem.ano;
                       end if;
                       select into elaporteuniversidad * FROM aporteuniversidad
                       WHERE  idaporte=elem.idaporte and    idcentroregionaluso=elem.idcentroregionaluso
                       and nrodoc=elcargo.nrodoc and tipodoc=elcargo.tipodoc 
                       and mes=elem.mes and anio=elem.ano;
                      if found then
                        delete from aporteuniversidad WHERE  idaporte=elem.idaporte and  
                        idcentroregionaluso=elem.idcentroregionaluso
                        and nrodoc=elcargo.nrodoc and tipodoc=elcargo.tipodoc and mes=elem.mes 
                        and anio=elem.ano;
                      end if;
                  end if;
      
                 end if; 

           


     
        select into elinformefacturacionaporte * FROM informefacturacionaporte WHERE 
        nroinforme=eldatofactura .nroinforme and 
        idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion
          and idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;
           if found then 
             delete from informefacturacionaporte  WHERE  nroinforme=eldatofactura .nroinforme 
             and idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion
             and idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;

           end if;
       delete from aporte WHERE  idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;
        
       delete  from concepto WHERE  mes=elaportejubpen.mes and ano=elaportejubpen.anio and idlaboral=eldatofactura.idlaboral 
and idconcepto='311' and nroliquidacion=eldatofactura.nroliquidacion;

      

     
    

  
--      end if; 
FETCH  losaportes INTO elem; 

end if; 
end if;

END LOOP;   



CLOSE losaportes;


 select into elinformefacturacionitem * FROM informefacturacionitem WHERE    
       nroinforme=eldatofactura .nroinforme and
       idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion;
          if found then 
            delete from informefacturacionitem  WHERE  nroinforme=eldatofactura .nroinforme 
            and idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion;
          end if;
       select into elinformefacturacionestado * FROM informefacturacionestado WHERE
       nroinforme=eldatofactura .nroinforme and 
       idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion;
          if found then 
            delete from informefacturacionestado WHERE  nroinforme=eldatofactura .nroinforme 
            and idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion;
        end if;



 select into elinforme * FROM informefacturacion WHERE  nroinforme=eldatofactura .nroinforme  
       and idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion;
        if found then 
           delete from informefacturacion WHERE   nroinforme=eldatofactura .nroinforme 
           and idcentroinformefacturacion=eldatofactura .idcentroinformefacturacion;
         end if;

          select into elimporterecibo * FROM importesrecibo WHERE  idrecibo=$1 and centro=$2;
             if found then 
                delete from  importesrecibo WHERE  idrecibo=$1 and centro=$2;
          end if;

          select into elrecibousuario * FROM recibousuario WHERE  idrecibo=$1 and centro=$2;
             if found then    
                delete from  recibousuario WHERE  idrecibo=$1 and centro=$2;
          end if;


          select into elrecibo * FROM recibo WHERE  idrecibo=$1 and centro=$2;
            if found then    
                delete from  recibo WHERE  idrecibo=$1 and centro=$2;
          end if;




     return true;
END;$function$
