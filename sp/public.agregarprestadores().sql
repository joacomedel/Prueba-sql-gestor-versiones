CREATE OR REPLACE FUNCTION public.agregarprestadores()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*/
DECLARE
    ridtiporeten bigint;
    rpres RECORD;
    rverificaprestador RECORD;
    rverificaprestadorprestadortipo RECORD;
    rusuario RECORD; 
    idprest bigint;
    presnombre varchar;
usu_rol  RECORD;
    cuit varchar;
    rprestador CURSOR FOR
               select trim(REPLACE(pcuit, '-', ''))::bigint as nuevoidprestador, * from tempprestador;
    rdirec RECORD;
    viddireccion bigint;
    vidcentrodireccion INTEGER;
    rdireccion RECORD;
    rdirecciones CURSOR FOR
                 select * from tempdireccion;
    rmatricula RECORD;
    rmatriculas CURSOR FOR
                select * from tempmatricula;
    rprestadorconfig RECORD;
    rprestadorconfig2 RECORD;
    profes varchar;
    rcuenta record;
    existemapeo RECORD;
    rcuentas cursor for
             select * from tempcuentas;
    rtiposretencion cursor for
                    select * from tempprestadortiporetencion;
    rtiporet record;
    pidctacte bigint;

BEGIN
--    vidcentrodireccion = centro();
-- Malapi 12-11-2014 Lo agrego pues se usa esta tabla pero en el modulo de mesa de entrada, aun no se esta generando en la aplicacion
IF NOT (iftableexists('tempprestadortiporetencion')) THEN 
    CREATE TEMP TABLE tempprestadortiporetencion (idtiporetencion INTEGER) WITHOUT OIDS;
END IF;

     OPEN rprestador;
     FETCH rprestador INTO rpres;
     WHILE  found LOOP
        presnombre = rpres.pdescripcion;
        if (rpres.idprestador=0) then --Inserta un Nuevo Prestador
           begin
             INSERT INTO prestador(idprestador,ptelefono,pcuit,pdescripcion,idcolegio,pfax,pemail,pwww,pcontacto,ptelefonomovil,idcondicioncompra,
                 pmerc,pgast,pnroiibb,idtiporetencion,idcondicioniva,pnombrefantasia,pesagrupador,nrocuentac,
                 pagenteiibb,pagenteiva,pagenteganancias,pcategoria,pobservacion,diaspago)
             VALUES (rpres.nuevoidprestador,rpres.ptelefono,rpres.pcuit,rpres.pdescripcion,rpres.idcolegio,rpres.pfax,rpres.pemail,rpres.pwww,rpres.pcontacto,
                 rpres.ptelefonomovil,rpres.idcondicioncompra,rpres.pmerc,rpres.pgast,rpres.pnroiibb,rpres.idtiporetencion,rpres.idcondicioniva,
                 rpres.pnombrefantasia,rpres.pesagrupador,rpres.nrocuentac,rpres.pagenteiibb,rpres.pagenteiva,rpres.pagenteganancias,rpres.pcategoria,rpres.pobservacion,rpres.diaspago);
         --    idprest = currval('prestador_idprestador_seq');
             idprest = rpres.nuevoidprestador;

              select into rprestadorconfig * from tempprestadorconfig;
              if found then 
                    --Dani 12-08-2019
                     INSERT INTO prestadorconfig(idprestador,pcgastodirosu,pcgastodirfarm)
                     VALUES(idprest,rprestadorconfig.pcgastodirosu,rprestadorconfig.pcgastodirfarm);
              end if;

             INSERT INTO prestadorctacte(idprestador,idprestadorctacte)VALUES(idprest,idprest);  --vas 31/08/2017
             if (not nullvalue(rpres.idtiporetencion)) then
                    insert into prestadortiporetencion values (idprest,rpres.idtiporetencion);
             end if;

             IF(not nullvalue(rpres.pcuit) AND rpres.pcuit <> '') THEN
                    insert into mapeoprestadores(idprestadorsiges,idprestadormultivac,update)
                    values(idprest,0,true);
                    
                    select into pidctacte idprestador from ctacteprestador where idctacte=replace(replace(rpres.pcuit,'-',''),'/','');
                    if not found then      
                         INSERT INTO ctacteprestador (idprestador ,idctacte ) VALUES (idprest, replace(replace(rpres.pcuit,'-',''),'/','') );
                    end if;
              
             ELSE
             -- No hay que hacer nada, pues el proveedor no tiene un cuit valido cargado
             END IF;
             INSERT INTO public.cliente(nrocliente,barra,idtipocliente,cuitini,cuitmedio,cuitfin,idcondicioniva,telefono,denominacion)
             VALUES (idprest,600,4,substring(rpres.pcuit,1,2),substring(rpres.pcuit,4,8),substring(rpres.pcuit,13,1),rpres.idcondicioniva,rpres.ptelefono::varchar(20),rpres.pdescripcion);
          
             IF (rpres.pdescripcion ILIKE '%farma%') THEN 
                INSERT INTO personajuridica(denominacion, idprestador) values (rpres.pdescripcion,rpres.nuevoidprestador);
             END IF; 
           end;

        else--Actualiza un Prestador
          begin
             idprest = rpres.idprestador;
             UPDATE prestador
             SET ptelefono=rpres.ptelefono,
                 pcuit=rpres.pcuit,
                 pdescripcion=rpres.pdescripcion,
                 idcolegio=rpres.idcolegio,
                 pfax=rpres.pfax,
                 pemail=rpres.pemail,
                 pwww=rpres.pwww,
                 pcontacto=rpres.pcontacto,
                 ptelefonomovil=rpres.ptelefonomovil,
                 idcondicioncompra=rpres.idcondicioncompra,
                 pmerc=rpres.pmerc,
                 pgast=rpres.pgast,
                 pnroiibb=rpres.pnroiibb,
                 idtiporetencion=rpres.idtiporetencion,
                 idcondicioniva=rpres.idcondicioniva,
                 pnombrefantasia=rpres.pnombrefantasia,
                 pesagrupador=rpres.pesagrupador,
                 nrocuentac=rpres.nrocuentac,
                 pagenteiibb=rpres.pagenteiibb,
                 pagenteiva=rpres.pagenteiva,
                 pagenteganancias=rpres.pagenteganancias,
                 pcategoria=rpres.pcategoria,
                 pobservacion=rpres.pobservacion,
                 diaspago=rpres.diaspago
                 WHERE idprestador=idprest;


           /*Dani 12-08-2019*/
            select into rprestadorconfig * from tempprestadorconfig;
           select into rprestadorconfig2 * from prestadorconfig where idprestador=idprest;
           
              if found then 
                     update prestadorconfig set pcgastodirosu=rprestadorconfig.pcgastodirosu,
                     pcgastodirfarm=rprestadorconfig.pcgastodirfarm
                     where idprestador=idprest;
              else
                     INSERT INTO prestadorconfig(idprestador,pcgastodirosu,pcgastodirfarm)
                     VALUES(idprest,rprestadorconfig.pcgastodirosu,rprestadorconfig.pcgastodirfarm);
              end if;
        


           IF (not nullvalue(rpres.pcuit) AND rpres.pcuit <> '') THEN
              SELECT INTO existemapeo * FROM mapeoprestadores WHERE idprestadorsiges=idprest;
              IF FOUND THEN
                 UPDATE mapeoprestadores
                        set    update=true, fechaupdate=now()
                        where idprestadorsiges=idprest;
              ELSE
                    insert into mapeoprestadores(idprestadorsiges,idprestadormultivac,update)
                    values(idprest,rpres.idmultivac,true);
              END IF;
           
           END IF;
             
           IF (rpres.pdescripcion ILIKE '%farma%') THEN 
                UPDATE personajuridica SET denominacion= rpres.pdescripcion WHERE idprestador=rpres.nuevoidprestador;
           END IF; 
             select into cuit replace(rpres.pcuit,'-','');
             UPDATE public.cliente
                    SET telefono=rpres.ptelefono::varchar(20),
                    idcondicioniva=rpres.idcondicioniva,
                    cuitini= substring(cuit,1,2),
                    cuitmedio= substring(cuit,3,8),
                    cuitfin= substring(cuit,11,1),
                    denominacion = rpres.pdescripcion
                    where nrocliente=idprest and barra=600;
             if not found then
                    INSERT INTO public.cliente(nrocliente,barra,idtipocliente,cuitini,cuitmedio,cuitfin,idcondicioniva,telefono)
                    VALUES (idprest,600,4,substring(rpres.pcuit,1,2),substring(rpres.pcuit,4,8),substring(rpres.pcuit,13,1),1,rpres.ptelefono::varchar(20));
             end if;
          end;
        end if;
          FETCH rprestador INTO rpres;
     END LOOP;
     CLOSE rprestador;

     OPEN rdirecciones;
     fetch rdirecciones into rdirec;
     while found loop
           if (rdirec.iddireccion=0) then--Inserta nueva direccionp
                 insert into direccion(barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)
                 values (rdirec.barrio,rdirec.calle,rdirec.nro,rdirec.tira,rdirec.piso,rdirec.dpto,rdirec.idprovincia,rdirec.idlocalidad);
                 viddireccion = currval('direccion_iddireccion_seq');
                 vidcentrodireccion = centro();
           else --Actualiza direccion
                --26-09-2022 MaLaPi como no se envia por java el idcentrodireccion intento encontrarlo
                 --Dani agrego el 061022 porq al actualizar la direccion del prestador , no hacia nada 
                 viddireccion=rdirec.iddireccion;
 
                SELECT INTO rdireccion * FROM direccion WHERE iddireccion=viddireccion AND (idcentrodireccion=centro() OR idcentrodireccion=99 OR idcentrodireccion=1) LIMIT 1 ;
                IF FOUND THEN 
                  vidcentrodireccion = rdireccion.idcentrodireccion;
                END IF;
                viddireccion = rdirec.iddireccion;
                update direccion
                set    barrio = rdirec.barrio,
                       calle = rdirec.calle,
                       nro = rdirec.nro,
                       tira = rdirec.tira,
                       piso = rdirec.piso,
                       dpto = rdirec.dpto,
                       idprovincia = rdirec.idprovincia,
                       idlocalidad = rdirec.idlocalidad
                where iddireccion=viddireccion and idcentrodireccion=vidcentrodireccion;
               

           end if;
           if (rdirec.tipo='l') then
              update prestador
                     set iddomiciliolegal = viddireccion,idcentrodomiciliolegal=vidcentrodireccion
                     where idprestador = idprest;
              update cliente
                     set iddireccion = viddireccion,idcentrodireccion=vidcentrodireccion
                     where nrocliente=idprest and barra=600;
           else
                         
               update prestador
               set iddomicilioreal = viddireccion,idcentrodomicilioreal=vidcentrodireccion
               where idprestador = idprest;
           end if;
           fetch rdirecciones into rdirec;
     end loop;
     CLOSE rdirecciones;
     
     delete from prestadortiporetencion
     where idprestador=idprest;
     
     open rtiposretencion;
     FETCH rtiposretencion into rtiporet;
     while found loop
           insert into prestadortiporetencion(idprestador,idtiporetencion)
           values (idprest,rtiporet.idtiporetencion);
          fetch rtiposretencion into rtiporet;
     end loop;
     close rtiposretencion;
     

     delete from matricula
     where idprestador=idprest;

     OPEN rmatriculas;
     fetch rmatriculas into rmatricula;
     while found loop
--           UPDATE profesional set pnombres=presnombre
--           where idprestador=idprest;
           select pnombres into profes
           from profesional where idprestador=idprest;
           if not found THEN
              insert into profesional (idprestador,pnombres)
                     values(idprest,presnombre);
           end if;
           INSERT INTO matricula(nromatricula,malcance,idprestador,mespecialidad)
           VALUES(rmatricula.nromatricula,rmatricula.malcance,idprest,rmatricula.mespecialidad);
           fetch rmatriculas into rmatricula;
     end loop;
     CLOSE rmatriculas;

     open rcuentas;
     fetch rcuentas into rcuenta;
     while found loop
           update cuentas
           set cbuini=rcuenta.cbuini,
               cbufin=rcuenta.cbufin,
               nrobanco=rcuenta.nrobanco,
               nrosucursal=rcuenta.nrosucursal,
               nrocuenta=rcuenta.nrocuenta,
               digitoverificador=rcuenta.digitoverificador,
               tipocuenta=rcuenta.tipocuenta,
               cemail=rcuenta.cemail
           where tipodoc=rcuenta.tipodoc and nrodoc=rcuenta.nrodoc;
           if not found then
              insert into cuentas (cbuini,cbufin,nrobanco,nrosucursal,nrocuenta,digitoverificador,cemail,tipocuenta,tipodoc,nrodoc)
              values (rcuenta.cbuini,rcuenta.cbufin,rcuenta.nrobanco,rcuenta.nrosucursal,rcuenta.nrocuenta,rcuenta.digitoverificador,
                      rcuenta.cemail,rcuenta.tipocuenta,rcuenta.tipodoc,rcuenta.nrodoc);
           end if;
           fetch rcuentas into rcuenta;
     end loop;
     close rcuentas;
    


    

--Malapi 01/10/2020
-- Corroboro si ya se encuentra un usuario para el prestador
           SELECT INTO rverificaprestador * FROM prestador WHERE idprestador = idprest; 
-----02/12/2024 Se modifica para que puedan agregar prestadores desde los centros
 IF centro() = 1 then          
          SELECT INTO rusuario * FROM w_usuarioweb WHERE uwnombre ilike rverificaprestador.pcuit;
          IF FOUND THEN
                  -- actualizo la pass con el md5 (pcuit)
                  UPDATE w_usuarioweb SET uwcontrasenia = md5(rverificaprestador.pcuit)
                  WHERE idusuarioweb = rusuario.idusuarioweb;

                  SELECT INTO usu_rol * FROM w_usuariorolweb WHERE idrolweb = 2 AND idusuarioweb = rusuario.idusuarioweb;
                  IF NOT FOUND THEN 
                          UPDATE  w_usuariorolweb SET idrolweb = 2 
                          WHERE idusuarioweb = rusuario.idusuarioweb;
                 END IF; 
          ELSE
                  INSERT INTO w_usuarioweb(idusuarioweb,uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar,uwtipo)   
		   	      VALUES(replace(rverificaprestador.pcuit,'-','')::bigint,rverificaprestador.pcuit,md5(rverificaprestador.pcuit),rverificaprestador.pemail,true,null,true,false,3);
		 
		 -- INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(currval('w_usuarioweb_idusuarioweb_seq'),15); -- el rol proveedor es 15   
                  INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(replace(rverificaprestador.pcuit,'-','')::bigint,2); -- el rol prestador es 2                   
		  INSERT INTO w_usuarioprestador(idusuarioweb,idprestador) VALUES(replace(rverificaprestador.pcuit,'-','')::bigint,rverificaprestador.idprestador);
           END IF;
      END if;


             SELECT INTO rverificaprestadorprestadortipo * FROM prestadorprestadortipo WHERE idprestador = rverificaprestador.idprestador; 
             IF FOUND THEN
              INSERT INTO prestadorprestadortipo(idprestador,idprestadortipo)VALUES(replace(rverificaprestador.pcuit,'-','')::bigint,1);
             END IF;

     RETURN TRUE;
END;$function$
