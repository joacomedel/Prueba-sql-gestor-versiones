CREATE OR REPLACE FUNCTION multivac.actualizarprestador(pidprestador integer, ppdireccion character varying, pptelefono character varying, ppdomiciliolegal character varying, ppcuit character varying, ppiva character, ppseguro boolean, ppvtopoliza date, ppfechavtornp date, ppnroregprestadores integer, ppdescripcion character varying, pidcolegio integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare
respuesta bigint;
auxN integer;
xMapeo record;
xPrestador record;
idSigesNuevo integer;
viddireccion bigint;

begin
      respuesta=0;
      select into xMapeo * from multivac.mapeoprestadores where idprestadormultivac = pidprestador;
      if not found then --No existe una tupla en Mapeos para el Prestador ingresado --> Insertar uno Nuevo
         select into xPrestador * from public.prestador where idprestador=pidprestador and pcuit like concat('%',ppcuit,'%');
         if not found then -- No existe un prestador en Siges con el mismo idprestador y cuit que en Multivac
            --select into auxN max(idprestador) + 1 from public.prestador;
            INSERT INTO public.prestador (pdireccion,ptelefono,pdomiciliolegal,pcuit,piva,pseguro,
                       pvtopoliza,pfechavtornp,pnroregpretadores,pdescripcion,idcolegio)
            VALUES (ppdireccion,pptelefono,ppdomiciliolegal,ppcuit,ppiva,ppseguro,
                       ppvtopoliza,ppfechavtornp,ppnroregprestadores,ppdescripcion,pidcolegio);
            auxN = currval('prestador_idprestador_seq');
            
            INSERT INTO prestadorctacte(idprestador)VALUES(auxN);

            
            idSigesNuevo=auxN;
            
            insert into direccion(calle,nro,idprovincia,idlocalidad)
                 values (ppdireccion,0,1,0);
            viddireccion = currval('direccion_iddireccion_seq');
            
            INSERT INTO public.cliente(nrocliente,barra,idtipocliente,cuitini,cuitmedio,cuitfin,idcondicioniva,telefono,iddireccion,idcentrodireccion)
            VALUES (auxN,600,4,substring(ppcuit,1,2),substring(ppcuit,4,8),substring(ppcuit,13,1),1,pptelefono,viddireccion,centro());
            
         else
             idSigesNuevo=xPrestador.idprestador;
             UPDATE public.prestador
             SET pdireccion=ppdireccion,ptelefono=pptelefono,pdomiciliolegal=ppdomiciliolegal,
                        pcuit=ppcuit,piva=ppiva,pseguro=ppseguro,pvtopoliza=ppvtopoliza,pfechavtornp=ppfechavtornp,
                        pnroregpretadores=ppnroregprestadores,pdescripcion=ppdescripcion,idcolegio=pidcolegio
             where idprestador=idSigesNuevo;
             
             UPDATE public.cliente
             SET telefono=pptelefono
             where nrocliente=idSigesNuevo and barra=600;
             
             
         end if;
         INSERT INTO multivac.mapeoprestadores (idprestadormultivac,idprestadorsiges,cuitmultivac)
         VALUES (pidprestador,idSigesNuevo,ppcuit);
         respuesta=idSigesNuevo;
      else
         UPDATE public.prestador
         SET pdireccion=ppdireccion,ptelefono=pptelefono,pdomiciliolegal=ppdomiciliolegal,
                        pcuit=ppcuit,piva=ppiva,pseguro=ppseguro,pvtopoliza=ppvtopoliza,pfechavtornp=ppfechavtornp,
                        pnroregpretadores=ppnroregprestadores,pdescripcion=ppdescripcion,idcolegio=pidcolegio
         where idprestador=xMapeo.idprestadorsiges;
         
         UPDATE public.cliente
         SET telefono=pptelefono
         where nrocliente=xMapeo.idprestadorsiges and barra=600;
         
         if not found then -- no existe un cliente para el proveedor
            insert into direccion(calle,nro,idprovincia,idlocalidad)
                 values (ppdireccion,0,1,0);
            viddireccion = currval('direccion_iddireccion_seq');
            INSERT INTO public.cliente(nrocliente,barra,idtipocliente,cuitini,cuitmedio,cuitfin,idcondicioniva,telefono,iddireccion,idcentrodireccion)
            VALUES (xMapeo.idprestadorsiges,600,4,substring(ppcuit,1,2),substring(ppcuit,4,8),substring(ppcuit,13,1),1,pptelefono,viddireccion,centro());
         end if;
         
         respuesta=xMapeo.idprestadorsiges;
      end if;
      return respuesta;
end;
$function$
