CREATE OR REPLACE FUNCTION public.prorrogarvencimientos(date, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  resultado boolean;
  

BEGIN
/*Realizo la modificacion de los titulares*/
          IF ($2=34)THEN
              update resolbec set fechafinlab = $1
               FROM afilibec
               where afilibec.idresolbe = resolbec.idresolbe;
          else
          IF ($2=32)THEN
               update cargo set fechafinlab = $1
               FROM public.persona
               JOIN ca.persona on nrodoc = penrodoc and tipodoc = idtipodocumento
               natural join ca.categoriaempleado 
               where public.persona.nrodoc = cargo.nrodoc
                     and cargo.iddepen = 'SOS'
                     and cargo.tipodoc = public.persona.tipodoc
                     --and persona.barra = $2
                     and (nullvalue(cefechafin) or cefechafin>current_date )
                     and idcategoriatipo = 1;

          ELSE
             IF ($2=35 or $2=36)THEN
              update persona set fechafinos = $1                
               where   (barra=$2) and fechafinos> current_date-30;
                update afilsosunc set idestado=2           
               where   (barra=$2) and (nrodoc,tipodoc) in
                                  (select nrodoc,tipodoc from persona                 
                                              where   (barra=$2) and fechafinos> current_date-30  
                                   );   
              /*Dani agrego  el 20092023 para que se pueda prorrogar por sistema los vtos de jubilados y pensionados */
              --  SELECT INTO resultado * FROM cambiarestadoconfechafinos(concat('persona.barra =' , $2 ));
            -- RAISE NOTICE 'ENTRO POR BARRAS 35 O 36 (%)',parametro;
                        

             else

              update cargo set fechafinlab = $1
               FROM persona
               where persona.nrodoc = cargo.nrodoc
                     and (cargo.idcateg) IN (SELECT idcateg
                                            FROM categoria
                                            WHERE categoria.tipoafil = 'NO DOCENTE'
                                            )
                     and cargo.tipodoc = persona.tipodoc
                     and persona.barra = $2;
              END IF;
          END IF;
          END IF;
/* Vivi 13-04-2010 modifico para que se actualicen las fechas finos correctamente  */
      --  SELECT INTO resultado * FROM cambiarestadoconfechafinos(concat('persona.barra =' , $2 ));

	
   RETURN resultado;
END;
$function$
