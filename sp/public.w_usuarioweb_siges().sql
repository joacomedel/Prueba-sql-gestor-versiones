CREATE OR REPLACE FUNCTION public.w_usuarioweb_siges()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
      
       c_usu_siges refcursor;
 --RECORD
       r_usu_siges RECORD;
 --VARIABLES 
	elidusuarioweb BIGINT;

BEGIN

	
    
      
    /*  OPEN c_usu_siges FOR SELECT DISTINCT dni, concat(login,'_siges') as uwnombre,'' as uwcontrasenia,'' as uwmail,	true as uwsuscripcionnl,null as 
                                 uwverificador,	true as uwactivo,false as uwlimpiar,	1 as uwtipo 
                          FROM w_usuariorolwebsiges
                          NATURAL JOIN usuario
                          NATURAL JOIN usuarioconfiguracion
                          WHERE  nullvalue(idusuarioweb)  ;*/

 OPEN c_usu_siges FOR SELECT DISTINCT dni, concat(login,'_siges') as uwnombre,'' as uwcontrasenia,'' as uwmail,	true as uwsuscripcionnl,null as 
                                 uwverificador,	true as uwactivo,false as uwlimpiar,	1 as uwtipo 
                          FROM usuario
                          NATURAL JOIN usuarioconfiguracion
                          LEFT JOIN w_usuariorolwebsiges  USING (dni)
                      --    WHERE dni = 32020988  --idusuario in (198,192,186,191)
                            
                           WHERE dni = '31414342'
;


      FETCH c_usu_siges into r_usu_siges;
      WHILE found LOOP
           INSERT  INTO w_usuarioweb (uwnombre,uwcontrasenia,uwmail,uwsuscripcionnl,uwverificador,uwactivo,uwlimpiar,uwtipo) VALUES (                 r_usu_siges.uwnombre, r_usu_siges.uwcontrasenia, r_usu_siges.uwmail, r_usu_siges.uwsuscripcionnl, r_usu_siges.uwverificador, r_usu_siges.uwactivo,  r_usu_siges.uwlimpiar, r_usu_siges.uwtipo ); 
            elidusuarioweb = currval('public.w_usuarioweb_idusuarioweb_seq');
            
           --OJOOOOOO Se deberia verificar si existe o no informacion en la tabla w_usuariorolwebsiges, si no existe se debe ingresar la tupla

            UPDATE w_usuariorolwebsiges SET idusuarioweb= elidusuarioweb
            WHERE  dni = r_usu_siges.dni;    
            IF NOT FOUND THEN 
                INSERT INTO w_usuariorolwebsiges(dni,idrolweb,idusuarioweb) VALUES(r_usu_siges.dni,13,elidusuarioweb);
              --  INSERT INTO w_usuariorolwebsiges(dni,idrolweb,idusuarioweb) VALUES(r_usu_siges.dni,1,elidusuarioweb);
            END IF;


      FETCH c_usu_siges into r_usu_siges;
      END loop;
      close c_usu_siges;
     
return 'true';
END;
$function$
