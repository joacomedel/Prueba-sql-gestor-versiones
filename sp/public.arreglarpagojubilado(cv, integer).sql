CREATE OR REPLACE FUNCTION public.arreglarpagojubilado(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
/*
Este SP se creo para arreglar los aportes de un jubilado donde tenia varios aportes que quedaron guardados con un año q no era el correcto. 
Recordar q solo afecta un grupo de aportes seteado a mano.....idaporte>=655074 and idcentroregionaluso=6;
*/
         elaportejubpen RECORD;
         elaporte RECORD;
	 elaportesinfactura RECORD;	
         elem RECORD;
         elconcepto RECORD;
         
         losaportes cursor for
              select * FROM aportejubpen WHERE  nrodoc=$1 and barra=$2 and idaporte>=655074 and idcentroregionaluso=6;
BEGIN
      
   
OPEN losaportes;
FETCH losaportes INTO elem;
WHILE  found LOOP
        --CASE  WHEN extract(YEAR from age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
        update  aportejubpen 
        set fechainiaport=to_timestamp(concat(EXTRACT(YEAR FROM fechainiaport)-1 ,'-',EXTRACT(MONTH FROM fechainiaport),'-10'),'YYYY-MM-DD'),
        fechafinaport=to_timestamp(concat(EXTRACT(YEAR FROM fechafinaport)-1 ,'-',EXTRACT(MONTH FROM fechafinaport),'-10'),'YYYY-MM-DD'),
        	anio=anio-1
        WHERE  idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;

        
        
        select into elaporte * FROM aporte WHERE  idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;
        if found then 
           update aporte  set ano=ano-1   WHERE idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;
        end if;

       select into elaportesinfactura * FROM aportessinfacturas WHERE  idaporte=elem.idaporte 
       and idcentroregionaluso=elem.idcentroregionaluso    and nrodoc=$1 and tipodoc=elem.tipodoc and mes=elaporte.mes and anio=elaporte.ano;
         if found then 
           update aportessinfacturas  set anio=anio-1   WHERE idaporte=elem.idaporte and idcentroregionaluso=elem.idcentroregionaluso;
        end if;
       select into elconcepto * FROM concepto WHERE   nroliquidacion=elaporte.nroliquidacion   and idconcepto=311 and idlaboral=elaporte.idlaboral and mes=elaporte.mes and ano=elaporte.ano;
         if found then 
           update concepto  set ano=ano-1   WHERE  nroliquidacion=elaporte.nroliquidacion   and idconcepto=311 and idlaboral=elaporte.idlaboral and mes=elem.mes and ano=elaporte.ano;
        end if;
  
FETCH losaportes INTO elem; 
END LOOP;   
CLOSE losaportes;

     



     return true;
END;
$function$
