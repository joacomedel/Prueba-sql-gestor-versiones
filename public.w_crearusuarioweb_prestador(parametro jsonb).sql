CREATE OR REPLACE FUNCTION public.w_crearusuarioweb_prestador(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
* select * from w_crearusuarioweb_prestador('{"cuit":"08216252","TipoDocumento":1}')
* Recibe como parametros el  numero de documento, tipo documento y mail
* Retorna boolean true si se a creado el usuario correctamente
*/
DECLARE
       --rfiltros record ;
       cprestador REFCURSOR;
       rprestador RECORD;
       rverificaprestador RECORD;
       rverificaprestadorprestadortipo RECORD;
       idusuariosecuencia integer;
       respuesta character varying;
       rusuario record;
       respuestajson jsonb;
      
begin
       
       --EXECUTE sys_dar_filtros($1) INTO rfiltros;
       -- Busco los datos de los prestadores
   

 IF (iftableexists('tempprestador') ) THEN
                       DROP TABLE tempprestador;
 END IF;


 IF (iftableexists('tempmatricula') ) THEN
                       DROP TABLE tempmatricula;
 END IF;



 IF (iftableexists('tempdireccion') ) THEN
                       DROP TABLE tempdireccion;
 END IF;


 IF (iftableexists('tempcuentas') ) THEN
                       DROP TABLE tempcuentas;
 END IF;



 IF (iftableexists('tempprestadortiporetencion') ) THEN
                      DROP TABLE tempprestadortiporetencion;
 END IF;

 IF (iftableexists('tempprestadorconfig') ) THEN
                      DROP TABLE tempprestadorconfig;
 END IF;



CREATE TEMP  TABLE tempprestador (		idprestador bigint NOT NULL,		idmultivac INTEGER,		pdireccion VARCHAR,		ptelefono VARCHAR,		pdomiciliolegal VARCHAR,		pcuit VARCHAR,		pseguro BOOLEAN,		pvtopoliza DATE,		pfechavtornp DATE,		pnroregpretadores INTEGER,		pdescripcion VARCHAR,		idcolegio INTEGER,		pfax VARCHAR,		pemail VARCHAR,		pwww VARCHAR,		pcontacto VARCHAR,		ptelefonomovil VARCHAR,		idcondicioncompra BIGINT,		pmerc BOOLEAN,		pgast BOOLEAN,		pnroiibb VARCHAR,		idtiporetencion BIGINT,		pnombrefantasia VARCHAR,		pesagrupador BOOLEAN,		nrocuentac VARCHAR,		pctabancaria VARCHAR,		pcbu VARCHAR,		idcondicioniva BIGINT,		iddomiciliolegal BIGINT,		iddomicilioreal BIGINT,		pagenteiibb BOOLEAN,		pagenteiva BOOLEAN,		pagenteganancias BOOLEAN,		pcategoria VARCHAR,		diaspago INTEGER,		pobservacion VARCHAR);

CREATE TEMP TABLE tempmatricula (					nromatricula INTEGER NOT NULL,					malcance VARCHAR NOT NULL,					idprestador bigint NOT NULL,					mespecialidad VARCHAR NOT NULL);

CREATE TEMP TABLE tempdireccion (				iddireccion BIGINT NOT NULL,				tipo VARCHAR(1) NOT NULL,				barrio VARCHAR,				calle VARCHAR NOT NULL,				nro INTEGER NOT NULL,				tira VARCHAR,				piso VARCHAR(5),				dpto VARCHAR(5),				idprovincia BIGINT NOT NULL,				idlocalidad BIGINT NOT NULL);

CREATE TEMP TABLE tempcuentas (nrocuenta BIGINT NOT NULL,										tipocuenta SMALLINT NOT NULL,										nrobanco INTEGER NOT NULL,										nrosucursal BIGINT NOT NULL,										digitoverificador SMALLINT,										nrodoc VARCHAR NOT NULL,										tipodoc INTEGER NOT NULL,										cbuini VARCHAR,										cbufin VARCHAR,										cemail VARCHAR);

CREATE TEMP TABLE tempprestadortiporetencion (idprestador BIGINT NOT NULL,	idtiporetencion INTEGER NOT NULL) ;
CREATE TEMP TABLE tempprestadorconfig (idprestador BIGINT NOT NULL,	pcgastodirosu BOOLEAN, pcgastodirfarm  BOOLEAN);

insert into tempprestador (idprestador,idmultivac,ptelefono,pcuit,pdescripcion,idcolegio,pfax,pemail,pwww,pcontacto,ptelefonomovil,idcondicioncompra,pmerc,pgast,pnroiibb, idcondicioniva,pnombrefantasia,pesagrupador,nrocuentac,	pagenteiibb,pagenteiva,pagenteganancias,pcategoria,diaspago,pobservacion)
VALUES (0					,0					,NULL					,parametro->>'cuit',parametro->>'denominacion',NULL,NULL,parametro->>'correo',NULL					,NULL					,NULL					,3					,TRUE					,FALSE					,NULL					,3					,parametro->>'denominacion',FALSE					,'20200'					,FALSE					,FALSE					,FALSE					,'A'					,30					,NULL);

insert into tempdireccion (iddireccion,tipo,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)				values (0,'l','','',0,'','','',1,20);
insert into tempdireccion (iddireccion,tipo,barrio,calle,nro,tira,piso,dpto,idprovincia,idlocalidad)				values (0,'r','','',0,'','','',1,20);

insert into tempcuentas (tipocuenta,cemail,cbuini,cbufin,nrobanco,nrosucursal,nrocuenta,digitoverificador,tipodoc,nrodoc)values (0,'','','',0,0,0,0,12,replace(parametro->>'cuit','-',''));

insert into tempprestadorconfig (idprestador,pcgastodirosu,pcgastodirfarm)				values (0,true,false);

IF parametro->>'matricula' <> 0 THEN 
insert into tempmatricula (idprestador,nromatricula,malcance,mespecialidad) values (replace(parametro->>'cuit','-','')::bigint,trim(parametro->>'matricula')::integer,'Neuquen',parametro->>'especialidad');
END IF;

         SELECT INTO rverificaprestador * FROM prestador WHERE pcuit = parametro->>'cuit'; 
         IF NOT FOUND THEN
             PERFORM from public.agregarprestadores();
         ELSE 

--Malapi 01/10/2020
-- Corroboro si ya se encuentra un usuario para el prestador
         
          SELECT INTO rusuario * FROM w_usuarioweb 
          WHERE uwnombre ilike rverificaprestador.pcuit 
                OR idusuarioweb = replace(rverificaprestador.pcuit,'-','')::bigint   ;
          IF FOUND THEN
                  -- actualizo la pass con el md5 (pcuit)
               /*vas090924   UPDATE w_usuarioweb SET uwcontrasenia = md5(rverificaprestador.pcuit)
                  WHERE idusuarioweb = rusuario.idusuarioweb;
                  UPDATE  w_usuariorolweb SET idrolweb = 2 
                  WHERE idusuarioweb = rusuario.idusuarioweb;   vas090924*/
          ELSE
                  INSERT INTO w_usuarioweb(idusuarioweb,uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar,uwtipo)   
		   	      VALUES(replace(rverificaprestador.pcuit,'-','')::bigint,rverificaprestador.pcuit,md5(rverificaprestador.pcuit),rverificaprestador.pemail,true,null,true,false,3);
		 
		 -- INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(currval('w_usuarioweb_idusuarioweb_seq'),15); -- el rol proveedor es 15   
                  INSERT INTO w_usuariorolweb(idusuarioweb,idrolweb)values(replace(rverificaprestador.pcuit,'-','')::bigint,2); -- el rol prestador es 2                   
		  INSERT INTO w_usuarioprestador(idusuarioweb,idprestador) VALUES(replace(rverificaprestador.pcuit,'-','')::bigint,rverificaprestador.idprestador);
           END IF;
             SELECT INTO rverificaprestadorprestadortipo * FROM prestadorprestadortipo WHERE idprestador = rverificaprestador.idprestador; 
             IF FOUND THEN
              INSERT INTO prestadorprestadortipo(idprestador,idprestadortipo)VALUES(replace(rverificaprestador.pcuit,'-','')::bigint,1);
             END IF;

         END IF;
        
                 
                
      SELECT INTO rusuario * FROM w_usuarioweb WHERE uwnombre ilike parametro->>'cuit';
          
      respuestajson = row_to_json(rusuario);   

return respuestajson;

end;
$function$
