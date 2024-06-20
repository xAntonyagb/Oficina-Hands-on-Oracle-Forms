CREATE OR REPLACE PROCEDURE INSERT_TIPO_VEICULO(
  I_NR_CODIGO IN NUMBER,
  I_DS_TIPO IN VARCHAR2,
  I_QTD_PORTAS IN NUMBER,
  I_QTD_RODAS IN NUMBER,
  I_DT_RECORD IN DATE DEFAULT SYSDATE,
  O_MSG OUT VARCHAR2
)
IS
  V_COUNT NUMBER;
  E_GERAL EXCEPTION;
  
BEGIN
  O_MSG := 'Tipo inserido com sucesso!';
  
  -- POPULANDO V_COUNT (VALIDA��O)
  BEGIN 
    SELECT COUNT(*)
    INTO V_COUNT
    FROM TIPO_VEICULO tv
    WHERE tv.nr_codigo = I_NR_CODIGO;
  EXCEPTION
    WHEN OTHERS THEN
      V_COUNT := 0;
  END;
  
  -- CASO O TIPO J� N�O ESTIVER REGISTRADO -> INSERIR
  IF NVL(V_COUNT, 0) = 0 THEN
    INSERT INTO TIPO_VEICULO tv
      (tv.nr_codigo, tv.ds_tipo, tv.qtd_portas, tv.qtd_rodas, tv.dt_record)
    VALUES
      (I_NR_CODIGO, I_DS_TIPO, I_QTD_PORTAS, I_QTD_RODAS, I_DT_RECORD);
    
    COMMIT;
   -- SE TEM REGISTRO -> EXCEPTION
  ELSE
    RAISE E_GERAL;
  END IF;

EXCEPTION
  WHEN E_GERAL THEN
    O_MSG := '[INSERT_TIPO_VEICULO]: Tipo j� existente. Tipo n�o foi inserido: ' || I_NR_CODIGO;
    ROLLBACK;
  WHEN OTHERS THEN
    O_MSG := '[INSERT_TIPO_VEICULO]: Erro ao inserir o tipo: ' || SQLERRM;
    ROLLBACK;
END INSERT_TIPO_VEICULO;
/
