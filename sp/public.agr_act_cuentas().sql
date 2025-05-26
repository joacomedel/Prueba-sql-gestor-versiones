CREATE OR REPLACE FUNCTION public.agr_act_cuentas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	cuentaTemp CURSOR FOR SELECT * FROM cuentas_temp;
	cuentaT RECORD;
	aux RECORD;
	resultado boolean;
        rusuario RECORD;

BEGIN
  SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN 
        rusuario.idusuario = 25;
     END IF;

	OPEN cuentaTemp;	
	FETCH cuentaTemp INTO cuentaT;
	WHILE  found LOOP
   		/*SELECT INTO aux * FROM cuentas
                               NATURAL JOIN persona
                               WHERE nrodoc = cuentaT.nrodoc AND barra = cuentaT.barra;*/
        SELECT INTO aux * FROM cuentas
                               NATURAL JOIN persona
                               WHERE nrodoc = cuentaT.nrodoc AND tipodoc = cuentaT.tipodoc;
	     IF FOUND THEN
               
          --tipocuenta=15 es a definir
		   UPDATE cuentas SET tipocuenta = case when nullvalue(cuentaT.tipocuenta) then
                                                  15 else cuentaT.tipocuenta::integer END
                           ,nrobanco = case when nullvalue(cuentaT.nrobanco) then 
                                                  substring(cuentaT.cbuini from 1 for 3)::integer else cuentaT.nrobanco END
                           ,nrosucursal = case when nullvalue(cuentaT.nrosucursal) then
                                                  substring(cuentaT.cbufin  from 5 for 2)::integer else cuentaT.nrosucursal END
                           ,nrocuenta =  case when nullvalue(cuentaT.nrocta) then
                                                  substring(cuentaT.cbufin from 7 for 7)::bigint else cuentaT.nrocta END
                           ,digitoverificador = case when nullvalue(cuentaT.digitoverificador) then
                                                  substring(cuentaT.cbufin from 13 for 1)::integer else  cuentaT.digitoverificador END
  
                           ,cbuini = cuentaT.cbuini
                           ,cbufin= cuentaT.cbufin
                           ,cuidusuario=rusuario.idusuario
			WHERE nrodoc = cuentaT.nrodoc AND tipodoc = cuentaT.tipodoc;
                --KR 26-05-22 SI CAMBIO la cuenta guardo el historico
                   IF cuentaT.cbuini <> aux.cbuini AND cuentaT.cbufin<> aux.cbufin THEN
                      UPDATE cuentashistorico SET chfechafin= now()
                           WHERE chnrobanco = aux.nrobanco
                              AND chnrosucursal = aux.nrosucursal
                              AND chnrocuenta = aux.nrocuenta
                              AND chdigitoverificador = aux.digitoverificador
                              AND chcbuini = aux.cbuini
                              AND chcbufin= aux.cbufin
			      AND nrodoc = aux.nrodoc AND tipodoc = aux.tipodoc and nullvalue(chfechafin);
                     INSERT INTO cuentashistorico(chtipocuenta,chnrobanco,chnrosucursal,chnrocuenta,chdigitoverificador,nrodoc,tipodoc,chcbuini,chcbufin,chidusuario,chfechainicio)
				VALUES (case when nullvalue(cuentaT.tipocuenta) then 15 else cuentaT.tipocuenta::integer END
,case when nullvalue(cuentaT.nrobanco) then substring(cuentaT.cbuini from 1 for 3)::integer else cuentaT.nrobanco END
,case when nullvalue(cuentaT.nrosucursal) then substring(cuentaT.cbufin  from 5 for 2)::integer else cuentaT.nrosucursal END
,case when nullvalue(cuentaT.nrocta) then substring(cuentaT.cbufin from 7 for 7)::bigint else cuentaT.nrocta END
,case when nullvalue(cuentaT.digitoverificador) then substring(cuentaT.cbufin from 13 for 1)::integer else  cuentaT.digitoverificador END
,cuentaT.nrodoc,cuentaT.tipodoc,cuentaT.cbuini,cuentaT.cbufin,rusuario.idusuario,aux.cufechainicio);
                  END IF; 
		ELSE
		    INSERT INTO cuentas (tipocuenta,nrobanco,nrosucursal,nrocuenta,digitoverificador,nrodoc,tipodoc,cbuini,cbufin,cuidusuario)
		    VALUES (case when nullvalue(cuentaT.tipocuenta) then 15 else cuentaT.tipocuenta::integer END
,case when nullvalue(cuentaT.nrobanco) then substring(cuentaT.cbuini from 1 for 3)::integer else cuentaT.nrobanco END
,case when nullvalue(cuentaT.nrosucursal) then substring(cuentaT.cbufin  from 5 for 2)::integer else cuentaT.nrosucursal END
,case when nullvalue(cuentaT.nrocta) then substring(cuentaT.cbufin from 7 for 7)::bigint else cuentaT.nrocta END
,case when nullvalue(cuentaT.digitoverificador) then substring(cuentaT.cbufin from 13 for 1)::integer else  cuentaT.digitoverificador END
,cuentaT.nrodoc,cuentaT.tipodoc,cuentaT.cbuini,cuentaT.cbufin,rusuario.idusuario);
		END IF;
		

--modificacion anterior, no chequeaba el estado del reintegro
/*update reintegro set tipocuenta=cuentaT.tipocuenta, nrocuenta=cuentaT.nrocta where
			((reintegro.nrodoc=cuentaT.nrodoc) and (reintegro.tipodoc=cuentaT.tipodoc)) and ((nullvalue(reintegro.tipocuenta) and nullvalue(reintegro.nrocuenta));*/

update reintegro set tipocuenta=cuentaT.tipocuenta, nrocuenta=cuentaT.nrocta
from (select nroreintegro, anio,idcentroregional, max(idcambioestado) as idcambioestado from restados group by nroreintegro, anio,idcentroregional) as estado natural join restados
where
  reintegro.nroreintegro = estado.nroreintegro and reintegro.anio = estado.anio and
  ((reintegro.nrodoc=cuentaT.nrodoc) and (reintegro.tipodoc=cuentaT.tipodoc)) and
  (restados.tipoestadoreintegro = 1 OR restados.tipoestadoreintegro = 2 OR  restados.tipoestadoreintegro = 5);


--((reintegro.nrodoc=cuentaT.nrodoc) and (reintegro.tipodoc=cuentaT.tipodoc)) and 
--
--exists(select estadoreintegrodesc from restados natural join
--	(select nroreintegro, anio, max(idcambioestado) as idcambioestado from restados group by --nroreintegro, anio) 		as poo
--	natural join 
--	tipoestadosreintegro where nroreintegro = reintegro.nroreintegro and anio= reintegro.anio 
--	and (estadoreintegrodesc = 'Pendiente' OR estadoreintegrodesc = 'Liquidable'));





	FETCH cuentaTemp INTO cuentaT;
	END LOOP;
	CLOSE cuentaTemp;
   return true;


END;$function$
