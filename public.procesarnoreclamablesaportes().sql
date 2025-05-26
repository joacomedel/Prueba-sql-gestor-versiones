CREATE OR REPLACE FUNCTION public.procesarnoreclamablesaportes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
*/
DECLARE
    --registros
      rreclaportes RECORD;
      peraporte RECORD;
      con RECORD;
      aux RECORD;
    --cursor
      cursorreclap CURSOR FOR SELECT * FROM tempnoreclamables;
BEGIN
    OPEN cursorreclap;
     FETCH cursorreclap INTO rreclaportes;
     WHILE  found LOOP
           
             INSERT INTO dh21noreclamable( mesingreso, anioingreso, nroliquidacion, nrolegajo,nrocargo, nroconcepto,
                                           importe,tipoconcepto,novedad1,novedad2, ordenimpresion,
                                  tipoescalafon,
    nroescalafon,
    codigoescalafon,
    regional,
    unidadacademica,
    dependencia,
    subdependencia,
    fuentefinanciamiento,
    programa,
    subprograma,
    proyecto,
    actividad,
    obra,
    finalidad,
    funcion,
    mesretroactivo,
    anioretroactivo,
    detalle)
             VALUES (rreclaportes.mesingreso, rreclaportes.anioingreso, rreclaportes.nroliquidacion, rreclaportes.nrolegajo,rreclaportes.nrocargo, rreclaportes.nroconcepto,
                                           rreclaportes.importe,rreclaportes.tipoconcepto,rreclaportes.novedad1,rreclaportes.novedad2, rreclaportes.ordenimpresion,
                                  rreclaportes.tipoescalafon,
    rreclaportes.nroescalafon,
    rreclaportes.codigoescalafon,
    rreclaportes.regional,
    rreclaportes.unidadacademica,
    rreclaportes.dependencia,
    rreclaportes.subdependencia,
    rreclaportes.fuentefinanciamiento,
    rreclaportes.programa,
    rreclaportes.subprograma,
    rreclaportes.proyecto,
    rreclaportes.actividad,
    rreclaportes.obra,
    rreclaportes.finalidad,
    rreclaportes.funcion,
    rreclaportes.mesretroactivo,
    rreclaportes.anioretroactivo,
    rreclaportes.detalle);

    SELECT INTO peraporte *
           FROM aporte
                      WHERE idcargo = rreclaportes.nrocargo
                       AND nroliquidacion = rreclaportes.nroliquidacion
                       AND ano = rreclaportes.anioingreso
                       AND mes = rreclaportes.mesingreso;
     
    IF FOUND THEN 
           --ELIMINO LOS APORTES DE LA PERSONA
           DELETE FROM aporte 
                      WHERE idcargo = rreclaportes.nrocargo
                       AND nroliquidacion = rreclaportes.nroliquidacion
                       AND ano = rreclaportes.anioingreso
                       AND mes = rreclaportes.mesingreso;
     END IF; 


     SELECT INTO con * FROM concepto WHERE concepto.idlaboral = rreclaportes.nrocargo
                                 AND concepto.idconcepto = rreclaportes.nroconcepto
                                 AND concepto.nroliquidacion = rreclaportes.nroliquidacion;
      

    IF FOUND THEN 
    
           --ELIMINO EL CONCEPTO
           DELETE FROM concepto 
                      WHERE concepto.idlaboral = rreclaportes.nrocargo
                            AND concepto.idconcepto = rreclaportes.nroconcepto
                            AND concepto.nroliquidacion = rreclaportes.nroliquidacion;
    END IF;
 --- ACTUALIZO LA FECHAFINOS
--busco datos de la persona
    SELECT INTO peraporte t.*
           FROM (SELECT legajosiu,nrodoc,tipodoc FROM afilidoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilinodoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afiliauto
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilirecurprop
                      ) as t
       
          WHERE t.legajosiu=rreclaportes.nrolegajo;


   SELECT into aux * FROM cambiarestadoconfechafinos('nrodoc=''peraporte.nrodoc'' or nrodoc=''peraporte.nrodoc''');


    
          DELETE FROM dh21 
          WHERE mesingreso= rreclaportes.mesingreso
                AND anioingreso= rreclaportes.anioingreso
                AND nroliquidacion= rreclaportes.nroliquidacion
                AND nrolegajo= rreclaportes.nrolegajo
                AND nrocargo= rreclaportes.nrocargo
                AND nroconcepto = rreclaportes.nroconcepto
                AND mesretroactivo =rreclaportes.mesretroactivo
                AND anioretroactivo =    rreclaportes.anioretroactivo
                AND importe = rreclaportes.importe;


      FETCH cursorreclap INTO rreclaportes;
     END LOOP;
     CLOSE cursorreclap;

     RETURN TRUE;
END;
$function$
