create or replace procedure EXCLUI_TIPO_VEICULO(I_Tipo IN NUMBER, O_MSG OUT VARCHAR2) is
  V_COUNT         NUMBER;
  V_COUNT_C       NUMBER;
  E_GERAL         EXCEPTION;
BEGIN
  
  -- POPULANDO V_COUNT
  BEGIN 
    SELECT COUNT(*)
    INTO   V_COUNT
    FROM   TIPO_VEICULO tv
    WHERE  tv.nr_codigo = i_Tipo;
  EXCEPTION
    WHEN OTHERS THEN
      V_COUNT := 0;
  END;
  
  -- validar cadastro de tipo
  IF NVL(V_COUNT, 0) = 0 THEN
    O_MSG := 'Tipo de veiculo ' || I_Tipo || ' não está cadastrado!';
    RAISE E_GERAL;
  END IF;
  
  
  -- POPULANDO V_COUNT_C
  BEGIN 
    SELECT COUNT(*)
    INTO   V_COUNT_C
    FROM   CARRO C
    WHERE  C.CD_TIPO = i_Tipo;
  EXCEPTION
    WHEN OTHERS THEN
      V_COUNT_C := 0;
  END;
  
  -- validar cadastro de carros com esse tipo
  IF NVL(V_COUNT_C, 0) != 0 THEN
    O_MSG := 'O tipo de veiculo ' || I_Tipo || ' já está vinculado em ' || V_COUNT_C || ' cadastros de carros!';
    RAISE E_GERAL;
  END IF;
  
  
  
  -- Excluir se tudo ok
  BEGIN
    DELETE FROM TIPO_VEICULO TV
    WHERE TV.NR_CODIGO = I_Tipo;
    
    O_MSG := 'Tipo ' || I_Tipo || ' excluído com sucesso!';
    COMMIT;
  END;
  
-- Exceptions  
EXCEPTION
  WHEN E_GERAL THEN
    O_MSG := 'Erro ao excluir: ' || O_MSG;
    ROLLBACK;

  WHEN OTHERS THEN
    ROLLBACK;
    O_MSG := 'Erro ao excluir tipo '|| I_Tipo || ' = ' || SQLERRM;
  
END EXCLUI_TIPO_VEICULO;
/
