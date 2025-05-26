CREATE OR REPLACE FUNCTION ca.abmliquidacionhorastrabajadas(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$declare

  salida varchar;
  param varchar;
  pfiltros record;
  cursorempleado refcursor;
  rfiltros record;
  unempleado  record;
  elidliq integer;
  elidliqitem integer;
  rlaliq record; 
  diassabados integer;
  diasdomingos integer;
  cantferiados integer;
  cant integer;
  cantdiaslaborables integer;
  vcantdiaslicsinsd  INTEGER DEFAULT 0;

begin
   cant = 0;
   EXECUTE sys_dar_filtros($1) INTO rfiltros;
   -- analizo la operacion que se desea realizar   
   IF( rfiltros.accion='regenerar' ) THEN
       UPDATE ca.liquidacionhorasempleado
       SET lheeliminado = now()
       WHERE idliquidacionhorasempleado = rfiltros.idliquidacionhorasempleado;
            
       SELECT INTO rlaliq * 
       FROM ca.liquidacionhorasempleado
       WHERE idliquidacionhorasempleado = rfiltros.idliquidacionhorasempleado;
       IF FOUND THEN 
                rfiltros.accion = 'nueva';
                rfiltros.amfechadesde  = rlaliq.lhefechadesde;
                rfiltros.amfechahasta  = rlaliq.lhefechahasta;
                rfiltros.idgrupoliquidaciontipo = rlaliq.idgrupoliquidaciontipo;

       END IF; 

   END IF; 
   IF( rfiltros.accion='nueva' ) THEN  -- Crea una nueva liquidacion
                   
                   SELECT INTO diassabados count (*) 
                   FROM ca.dardiasx(rfiltros.amfechadesde::date, rfiltros.amfechahasta::date, 6)  ; 

                   SELECT INTO diasdomingos count (*) 
                   FROM ca.dardiasx(rfiltros.amfechadesde::date, rfiltros.amfechahasta::date, 0)  ;  

                   SELECT INTO cantferiados count (*)
                   FROM ca.feriado 
                   WHERE fefecha >=  rfiltros.amfechadesde
                         AND fefecha <= rfiltros.amfechahasta ;




                
                                
                  

                   IF(rfiltros.idgrupoliquidaciontipo = 1)   THEN
                           cantdiaslaborables =  ((to_date(rfiltros.amfechahasta,'yyyy-mm-dd') - to_date(rfiltros.amfechadesde  ,'yyyy-mm-dd') +1) -(diassabados +	diasdomingos +	cantferiados));

                  ELSE   
                            cantdiaslaborables =  ((to_date(rfiltros.amfechahasta,'yyyy-mm-dd') - to_date(rfiltros.amfechadesde  ,'yyyy-mm-dd') +1) -(diasdomingos +	cantferiados));
                  END IF;
                   INSERT INTO ca.liquidacionhorasempleado(lhefechadesde,lhefechahasta,idgrupoliquidaciontipo	,lhecantsabados ,  lhecantdomingos,lhecantferiados,lhecantdiaslaborables)
                          VALUES(rfiltros.amfechadesde::date, rfiltros.amfechahasta::date,rfiltros.idgrupoliquidaciontipo::integer,diassabados,diasdomingos,cantferiados,cantdiaslaborables);
                   elidliq = currval('ca.liquidacionhorasempleado_idliquidacionhorasempleado_seq');
 

                   OPEN cursorempleado FOR SELECT DISTINCT idpersona
                                            FROM ca.empleado
                                            NATURAL JOIN ca.grupoliquidacionempleado
                                            NATURAL JOIN ca.movimientos
                                            WHERE idgrupoliquidaciontipo = rfiltros.idgrupoliquidaciontipo
                                                  AND mofecha >= rfiltros.amfechadesde
                                                  AND mofecha <= rfiltros.amfechahasta;
                                                  
                                                  
                   FETCH cursorempleado INTO unempleado;
                   WHILE FOUND LOOP
                               param =  concat('{amfechadesde=',rfiltros.amfechadesde, ',amfechahasta=',rfiltros.amfechahasta,' ,idpersona= ',unempleado.idpersona,'  }')::varchar;
                               perform ca.reportehorastrabajadas(param);  -- este SP genera una temporal con los movimientos en el rango de fecha del empleado;

--RAISE NOTICE 'param (%)',param;
                               INSERT INTO ca.liquidacionhorasempleadoitem(
idpersona,idliquidacionhorasempleado,lheicanthorastrabajadas,lheicanthorajornada,lheicanthorastotaljornada,lheicanthorasextras,
lheihrextrassosunc,lheihorainiciojornada,lheihorafinjornada,lheihorario,lheihasta15,lheimas15,lheiincumplimientoh,lheiomisionfichadoingreso,lheiomisionfichadoegreso)
                                             ( SELECT unempleado.idpersona,elidliq,
                                                    SUM( to_char(canthorastrabajadas,'HH24:MI:SS')::interval ) 
                                                  , MIN( to_char(canthorajornada,'HH24:MI:SS')::interval  ) 
                                                  , SUM( to_char(canthorajornada,'HH24:MI:SS')::interval  )  
                                                  , SUM( canthorasextras) as canthorasextras
                                                  , SUM( hrextrassosunc) as hrextrassosunc
                                                  , MIN( horainiciojornada) as horainiciojornada
                                                  , MIN( horafinjornada) as horafinjornada 
                                                  , SUM(CASE WHEN (horaentrada <=horainiciojornada) THEN 1 ELSE 0 END)
                                                  , SUM(
CASE WHEN (horaentrada >horainiciojornada AND
(to_char(horainiciojornada,'HH24:MI:SS')::interval - to_char(horaentrada,'HH24:MI:SS')::interval) <='15:00:00') THEN 1 ELSE 0 END) hasta15
                                                  , SUM( 
CASE WHEN (horaentrada >horainiciojornada AND (to_char(horainiciojornada,'HH24:MI:SS')::interval - to_char(horaentrada,'HH24:MI:SS')::interval) >'15:00:00') THEN 1 ELSE 0 END) mas15
                                                  , SUM( 
CASE WHEN (horaentrada >horainiciojornada AND (to_char(horainiciojornada,'HH24:MI:SS')::interval - to_char(horaentrada,'HH24:MI:SS')::interval) >'15:00:00'  AND (horaalida<horafinjornada)) THEN 1 ELSE 0 END) 
--5 es el reloj para fichadas manuales
                                                  , SUM(lheiomisionfichadoingreso)
                                                  , SUM(lheiomisionfichadoegreso)

                                              FROM temptablasalida
                                              WHERE  nullvalue(idferiado) and  nullvalue(idlicencia)
                                              
                                );
                                
                                elidliqitem = currval('ca.liquidacionhorasempleadoitem_ididliquidacionhorasempleadoit_seq');
                                UPDATE ca.liquidacionhorasempleadoitem
                                SET lheicantdiaslic = T.candiaslicencia 
                                    , lheicandiasferiados = T.candiasferiados
                                 
                                FROM (
                                     SELECT SUM(CASE WHEN (nullvalue(idferiado)) THEN 0
                                                     ELSE 1 END
                                                ) as candiasferiados
                                            , SUM( CASE WHEN (nullvalue(idlicencia)) THEN 0
--KR 28-07-19 Solo cuento los dias de licencia que se tomaron dentro del periodo de liquidacion 
                                                     ELSE (to_date((to_date(CASE WHEN ts.lifechafin > rfiltros.amfechahasta::DATE THEN rfiltros.amfechahasta::DATE ELSE ts.lifechafin END,'yyyy-mm-dd') ),'yyyy-mm-dd') - to_date(ts.fecha,'yyyy-mm-dd')+1 ) END
                                            )as candiaslicencia 
                                           
                                     FROM temptablasalida as ts
                                     LEFT JOIN licencia  using(idlicencia) 
                                     LEFT JOIN licenciatipo using(idlicenciatipo)
/* KR 26-08-19 COMENTO EL WHERE, no es necesario, el case controla los nulos, y necesito datos para aquellos empleados que no han tenido licencia o si en ese mes no hubo feriado alguno. Con la restriccion actual del where no encuentro a vivi en julio, pq no tomo licencia-- esperado por (ltpordia OR	ltdiascorridos) */
                         --            WHERE (ltpordia OR	ltdiascorridos) AND NOT (nullvalue(idferiado) OR  nullvalue(idlicencia))
                                     
                                ) as T
                                WHERE idliquidacionhorasempleadoitem = elidliqitem  ;

                                UPDATE ca.liquidacionhorasempleadoitem                                
                                SET lheicanhoraxlic = T.canthoraslic
                                    
                                    --- ,lheicanthorastotaljornada = lheicanthorastotaljornada - T.canthoraslic
                                FROM  (
                                     SELECT SUM(ltcanhoraspermiso::time)  as canthoraslic
                                     FROM temptablasalida
                                     JOIN licencia  using(idlicencia)
                                     JOIN  licenciatipo using(idlicenciatipo)
                                     WHERE  not(ltpordia)
                                ) AS T
                                WHERE idliquidacionhorasempleadoitem = elidliqitem  ;


--KR 26-08-19 REcupero cuantos son los dias sabados, domingos si los hubiera en el tiempo de licencia. Ver feriados
  
                               SELECT INTO vcantdiaslicsinsd CASE WHEN NULLVALUE(cantsaydo_enlic) THEN 0 ELSE cantsaydo_enlic END
                               FROM temptablasalida WHERE not nullvalue(idlicencia);

 RAISE NOTICE 'vcantdiaslicsinsd (%)',vcantdiaslicsinsd;
                                UPDATE ca.liquidacionhorasempleadoitem
                                SET lheicandiasanalizados =  T.cantdias +  lheicantdiaslic 
                               ,lheidiajusticados =  (lheicantdiaslic- CASE WHEN nullvalue(vcantdiaslicsinsd) THEN 0 ELSE vcantdiaslicsinsd END)
                               ,lheidiasinjusticados =  (cantdiaslaborables -  T.cantdias - CASE WHEN nullvalue(lheicantdiaslic) THEN 0 else  lheicantdiaslic END+ CASE WHEN nullvalue(vcantdiaslicsinsd) THEN 0 ELSE vcantdiaslicsinsd END)
                                FROM (SELECT  COUNT(*) as cantdias 
                                      FROM (
                                           SELECT DISTINCT fecha  
                                           FROM  temptablasalida
                                           WHERE nullvalue(idferiado) and nullvalue(idlicencia)
                                     ) as D
                                      
                                )as T
                                WHERE idliquidacionhorasempleadoitem = elidliqitem  ;
                              --  DROP TABLE temptablasalida;
 

                                 UPDATE ca.liquidacionhorasempleadoitem  SET                                
-- KR 26-08-19 los trabajados SON los laborales menos los ausentes. Los ausentes son la suma de los justificados + injustificados
                                 lheicandiastrabajados = cantdiaslaborables
/*KR 26-08-19  dias ausentes justificados menos si fueron lic corridas los sabados y domingos*/
                                  -lheidiajusticados
/*KR 26-08-19  dias ausentes injustificados*/
                                  -lheidiasinjusticados
/*KR 11-09-19 Pidieron tbn guardar el indice de horas trabajadas*/
                                  , lheiindicehoras = extract(hour from lheicanthorastrabajadas)/extract(hour from lheicanthorastotaljornada)                                    WHERE idliquidacionhorasempleadoitem = elidliqitem  ;
                            
                   cant = cant+1;
                   FETCH cursorempleado INTO unempleado;
                   END LOOP;
    
        
   END IF;



return cant;
end;$function$
