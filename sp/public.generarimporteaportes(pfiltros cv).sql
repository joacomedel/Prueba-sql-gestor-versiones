CREATE OR REPLACE FUNCTION public.generarimporteaportes(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD       
runac RECORD;
runaci RECORD;
ridiva RECORD;
rapconf  RECORD;

--CURSOR 
cursorac REFCURSOR;
cursoraci REFCURSOR;

--VARIABLES
vbrutoaumento DOUBLE PRECISION;
vbrutoaportar DOUBLE PRECISION;
vbrutoimporte DOUBLE PRECISION;
vusuario INTEGER; 
vimporteiva DOUBLE PRECISION;
vimportetotal DOUBLE PRECISION;

BEGIN
/*
select * from excel_aportes  join (
select nrodoc, aciimportebruto from aporteconfiguracion natural join aporteconfiguracionimportes
where acfechainicio >='2020-07-01'
group by nrodoc, aciimportebruto
having count(*)>1) as t on excel_aportes.nrodoc=t.nrodoc

order by excel_aportes.nrodoc
*/

IF NOT iftableexists('temp_aporteconfiguracion') THEN
  CREATE TEMP TABLE temp_aporteconfiguracion (
    nrodoc character varying(8),
    tipodoc smallint,
    acporcentaje real,
    acimportebruto real,
    acimporteaporte real,
    descripcion character varying(60),
    aciimportesiniva numeric,
    aciimporteiva numeric,
    aciimportetotal numeric,
    tarea text,
    presentonota text,
    acincrementomasivo boolean default true, 
    idiva integer
);

 -- DELETE FROM temp_aporteconfiguracion;
 INSERT INTO temp_aporteconfiguracion( nrodoc, tipodoc, acporcentaje, acimportebruto, acimporteaporte, descripcion, idiva, tarea, presentonota,acincrementomasivo) 
 --SELECT nrodoc, 1, acporcentaje, bruto, aportesiniva, 'Ingresado desde generarimporteaportes. ', 3 FROM excel_aportes;-- WHERE idexcelaportes<=25;
  
 select nrodoc,1, porcentaje as acporcentaje, importebruto, importeaporte, 'Ingresado desde generarimporteaportes con archivo.  ',3  ,tarea,presentonota,CASE WHEN trim(incrementomasivo) = 'true' THEN true ELSE false END as incrementomasivo  
 from  temporal_jubilados 
 where nullvalue(fechauso) AND (trim(replace(tarea,' ','')) ilike '%aportenuevo%' or trim(replace(tarea,' ','')) ilike '%corregirimportefacturar%' )
--KR 03-03-23 agrego que deje afuera a las novedades anuladas x el usuario TKT 5696
 AND nullvalue(tjborrado);

ELSE 
 --  DELETE FROM temp_aporteconfiguracion;
END IF;


 --TEMPORAL MIENTRAS NO ESTE LA INTERFACE KR 04-05-20



 vusuario = sys_dar_usuarioactual();
   

 OPEN cursorac FOR SELECT nrodoc, 1 as tipodoc, 
                          round((sum(acimporteaporte)*100/sum(acimportebruto))::numeric, 2) acporcentaje, 
                          round(sum(acimportebruto)::numeric,2) acimportebruto, 
                          round(sum(acimporteaporte)::numeric,2) acimporteaporte 
                   FROM  temp_aporteconfiguracion  
                   GROUP BY nrodoc, tipodoc ;
 FETCH cursorac INTO runac;
 WHILE FOUND LOOP
             SELECT INTO rapconf * 
             from aporteconfiguracion 
             WHERE nrodoc=runac.nrodoc 
                   AND tipodoc=runac.tipodoc 
                   AND nullvalue(acfechafin);
        
             IF FOUND THEN 
                    UPDATE aporteconfiguracion 
                    SET acfechafin=now() 
                    WHERE idaporteconfiguracion=rapconf.idaporteconfiguracion AND 
                          idcentroaporteconfiguracion=rapconf.idcentroaporteconfiguracion ;
                 
                   --KR 2021-10  -07 UPDATEO TBN la fechafin de la tabla  aporteconfiguracionimportes
                    UPDATE aporteconfiguracionimportes 
                    SET acifechafin=now() 
                    WHERE idaporteconfiguracion=rapconf.idaporteconfiguracion AND 
                           idcentroaporteconfiguracion=rapconf.idcentroaporteconfiguracion ;

              END IF;

              INSERT INTO aporteconfiguracion (idcentroaporteconfiguracion,nrodoc,tipodoc,acporcentaje, 
                     acimportebruto,acimporteaporte,acfechafin,acfechainicio,descripcion)
              VALUES(centro(),runac.nrodoc,runac.tipodoc,runac.acporcentaje,runac.acimportebruto,
                     runac.acimporteaporte,null,now()::date, 'Aporte generado desde generarimporteaportes');
   
         FETCH cursorac INTO runac;
 END LOOP;

 CLOSE cursorac;


 OPEN cursoraci FOR SELECT temp_aporteconfiguracion.*,	idaporteconfiguracion,	idcentroaporteconfiguracion
                FROM  temp_aporteconfiguracion 
                JOIN aporteconfiguracion USING(nrodoc,tipodoc) 
                WHERE nullvalue(acfechafin);-- AND acfechainicio>='2020-05-01' ;
 FETCH cursoraci INTO runaci;
 WHILE FOUND LOOP

      SELECT INTO ridiva * FROM tipoiva WHERE idiva=runaci.idiva;
      vimporteiva = round(CAST((runaci.acimporteaporte*ridiva.porcentaje) AS numeric),2);
      vimportetotal = vbrutoaportar+vimporteiva;
     
      INSERT INTO aporteconfiguracionimportes
(idcentroaporteconfiguracion,idaporteconfiguracion,aciimportesiniva,aciimporteiva,aciimportetotal,idiva,idusuario,aciporcentaje,aciimportebruto,aciaumentomasivo)
              VALUES(runaci.idcentroaporteconfiguracion,runaci.idaporteconfiguracion,runaci.acimporteaporte, vimporteiva, vimportetotal, runaci.idiva, vusuario,runaci.acporcentaje,runaci.acimportebruto,runaci.acincrementomasivo);       


 FETCH cursoraci INTO runaci;
 END LOOP;
 CLOSE cursoraci;

 
 UPDATE temporal_jubilados SET fechauso = now() 
 where nullvalue(fechauso) AND (trim(replace(tarea,' ','')) ilike '%aportenuevo%' or trim(replace(tarea,' ','')) ilike '%corregirimportefacturar%' );


return '';
END;

$function$
