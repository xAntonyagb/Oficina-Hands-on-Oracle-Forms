CREATE OR REPLACE PROCEDURE insertTipoVeiculo(
  I_NR_CODIGO IN NUMBER,
  I_DS_TIPO IN VARCHAR2,
  I_QTD_PORTAS IN NUMBER,
  I_QTD_RODAS IN NUMBER,
  I_DT_RECORD IN DATE DEFAULT SYSDATE,
  O_MSG OUT VARCHAR2
)
IS
  v_count NUMBER;
  e_geral EXCEPTION;
  
BEGIN
  O_MSG := 'Tipo inserido com sucesso!';


  -- POPULANDO V_COUNT
  BEGIN 
    SELECT COUNT(*)
    INTO v_count
    FROM TIPO_VEICULO tv
    WHERE tv.nr_codigo = I_NR_CODIGO;
  EXCEPTION
    WHEN OTHERS THEN
      v_count := 0;
  END;
  
  -- SE NÃO TEM PLACA INSERE
  IF NVL(v_count, 0) = 0 THEN
    INSERT INTO TIPO_VEICULO(NR_CODIGO,
                             DS_TIPO,
                             QTD_PORTAS,
                             QTD_RODAS,
                             DT_RECORD)
                             VALUES(I_NR_CODIGO,
                             I_DS_TIPO,
                             I_QTD_PORTAS,
                             I_QTD_RODAS,
                             I_DT_RECORD);
    
    COMMIT;
    
   -- se tem placa -> exception
  ELSE
    RAISE e_geral;
  END IF;

EXCEPTION
  WHEN e_geral THEN
    O_MSG := '[InsertTipoVeiculo]: Tipo já existente. Tipo não foi inserido: ' || I_NR_CODIGO;
    ROLLBACK;
  WHEN OTHERS THEN
    O_MSG := '[InsertTipoVeiculo]: Erro ao inserir o tipo. ' || SQLERRM;
    ROLLBACK;
END insertTipoVeiculo;
/
