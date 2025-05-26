CREATE OR REPLACE FUNCTION ca.ft_afip_931ingresarregistro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       elnuevoreg record;
       liqafil record;
       diferencia double precision;
       impremtotal double precision;
       impasignaciones  double precision;
       laremtotal  double precision;
       impreunerativo  double precision;
BEGIN


  elnuevoreg = NEW;
  --- remtotal = sueldoyadic + HorasExtras + zonadesfavorable + vacaciones + Adicionales + Premio + noremunerativo

--La base imponible 2 debe coincidir con el sueldo + horas extras + plus por zona desfavorable + vacaciones + adicionales + premios ---   + SAC  .
--  impremtotal =  elnuevoreg.sueldoyadic + elnuevoreg.horasextras + elnuevoreg.impzonadesf + elnuevoreg.vacaciones  + elnuevoreg.montoadicionales + elnuevoreg.premio + elnuevoreg.noremunerativo;
    impreunerativo = replace( elnuevoreg.sueldoyadic, '@', '')::double precision
               + replace( elnuevoreg.horasextras, '@', '')::double precision
               + replace( elnuevoreg.impzonadesf, '@', '')::double precision
               + replace( elnuevoreg.vacaciones, '@', '')::double precision
               + replace( elnuevoreg.montoadicionales, '@', '')::double precision
               + replace( elnuevoreg.premio, '@', '')::double precision

               + replace( elnuevoreg.sac, '@', '')::double precision
;
               
   impremtotal =  round( impreunerativo::numeric,2)  + round(replace( elnuevoreg.noremunerativo, '@', '')::numeric,2) ;

  laremtotal = replace(elnuevoreg.remtotal , '@', '')::double precision;
  diferencia =  laremtotal  - impremtotal ;
  
  if (abs(diferencia)>0 and abs(diferencia)<1 ) THEN
             laremtotal = impremtotal;
             UPDATE ca.afip_931  SET remtotal =  lpad(trunc(impremtotal::numeric,2),12,'@')
             WHERE limesliq = elnuevoreg.limesliq
                   and lianioliq = elnuevoreg.lianioliq
                    and  idpersona =elnuevoreg.idpersona;
  END IF;
  

 --- VAS Si los disas trabajados = 0 le pongo 30 MOODIFICAR ERA PARA QUE TOME A LAS PASANTES
 
  UPDATE ca.afip_931 SET
         cantfiastrab = '000000030'
  WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq
        and  idpersona = elnuevoreg.idpersona and cantfiastrab::numeric = 0;



  UPDATE ca.afip_931 SET
         imponibleuno = lpad( remtotal  ,12,'@')
  WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq
        and  idpersona = elnuevoreg.idpersona
        AND (  replace( imponibleuno, '@', '') ::double precision - laremtotal > 0 AND replace( imponibleuno, '@', '') ::double precision - laremtotal  <1 ) ;


  UPDATE ca.afip_931 SET
         remimptre = lpad( remtotal  ,12,'@')
  WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona = elnuevoreg.idpersona
        AND (  replace( remimptre, '@', '')::double precision - laremtotal > 0 AND replace( remimptre, '@', '')::double precision - laremtotal   <1 );

 UPDATE ca.afip_931 SET
         remimpcuatro = lpad( remtotal  ,12,'@')
  WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona = elnuevoreg.idpersona
        AND ( replace( remimpcuatro, '@', '')::double precision - laremtotal > 0 AND  replace( remimpcuatro, '@', '')::double precision - laremtotal  <1 );

  UPDATE ca.afip_931 SET
         remcinco = lpad( remtotal  ,12,'@')
  WHERE  limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona = elnuevoreg.idpersona
        AND (  replace( remcinco, '@', '')::double precision - laremtotal > 0 AND replace( remcinco, '@', '')::double precision - laremtotal  <1 )  ;

 UPDATE ca.afip_931 SET
         remimpocho = lpad( remtotal  ,12,'@')
  WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona = elnuevoreg.idpersona
        AND (  replace( remimpocho, '@', '')::double precision - laremtotal > 0 AND replace( remimpocho, '@', '')::double precision - laremtotal  <1 )  ;

  UPDATE ca.afip_931 SET
         remimnueve = lpad( remtotal  ,12,'@')
  WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona = elnuevoreg.idpersona
        AND (replace( remimnueve, '@', '')::double precision - laremtotal > 0 AND replace( remimnueve, '@', '')::double precision - laremtotal  <1 )  ;

       

UPDATE ca.afip_931 SET
         remimnueve = lpad( remtotal  ,12,'@')
  WHERE  limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona = elnuevoreg.idpersona;
--        AND (  replace( remimnueve, '@', '')::double precision - laremtotal > 0 AND replace( remimnueve, '@', '')::double precision - laremtotal  <1 )  ;

 
--   IF ( imponible=1 OR imponible = 3 OR imponible = 4 OR imponible = 5  OR imponible = 8 ) THEN



  -- Corroboro los decimales de imp2 con imp3
 

/* if(     (abs(replace( elnuevoreg.remimpdos, '@', '')::double precision - impreunerativo)::numeric) >=0.0
          AND
          (abs(replace( elnuevoreg.remimpdos, '@', '')::double precision - impreunerativo)::numeric) <=1.1
        ) THEN
  */         UPDATE ca.afip_931 SET remimpdos =  lpad(round(impreunerativo::numeric,2),12,'@')
            WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona =elnuevoreg.idpersona;
  ---END IF;
 
/*
 if(     (abs(replace( elnuevoreg.remimpdos, '@', '')::double precision - replace( elnuevoreg.remimptre, '@', '')::double precision )::numeric) >=0.0
          AND
          (abs(replace( elnuevoreg.remimpdos, '@', '')::double precision - replace( elnuevoreg.remimptre, '@', '')::double precision)::numeric) <=1.1
        ) THEN
           UPDATE ca.afip_931 SET remimpdos =   elnuevoreg.remimptre
            WHERE limesliq = elnuevoreg.limesliq AND lianioliq = elnuevoreg.lianioliq and  idpersona =elnuevoreg.idpersona;
  END IF;
*/


  RETURN NEW;
END;
$function$
