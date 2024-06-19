CREATE OR REPLACE FUNCTION retorna_quantidade_tipo(i_cd_tipo IN NUMBER) RETURN NUMBER IS
  V_Count NUMBER;
BEGIN
  
  BEGIN
    SELECT COUNT(*) INTO V_COUNT FROM CARRO c WHERE c.cd_tipo = i_cd_tipo;
  EXCEPTION
    WHEN OTHERS THEN
      V_COUNT := 0;
  END;
  
  RETURN(V_Count);
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END retorna_quantidade_tipo;
/
