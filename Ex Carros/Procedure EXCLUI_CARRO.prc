create or replace procedure EXCLUI_CARRO(I_placa IN NUMBER, O_MSG OUT VARCHAR2) is
  V_COUNT NUMBER;
  E_GERAL EXCEPTION;
BEGIN
  
  -- popular v_count
  BEGIN
    SELECT COUNT(*) INTO V_COUNT FROM CARRO c WHERE c.nr_placa = I_placa;
  EXCEPTION
    WHEN OTHERS THEN
      V_COUNT := 0;
  END;
  
  -- validar cadastro de placa
  IF NVL(V_COUNT, 0) = 0 THEN
    O_MSG := 'Placa ' || I_placa || ' não está cadastrada!';
    RAISE E_GERAL;
  END IF;

  -- Excluir se tudo ok
  BEGIN
    DELETE FROM CARRO C
    WHERE C.NR_PLACA = I_placa;
    
    O_MSG := 'Placa ' || I_placa || 'excluída com sucesso!';
    COMMIT;
  END;
  
-- Exceptions  
EXCEPTION
  WHEN E_GERAL THEN
    O_MSG := 'Erro ao excluir: ' || O_MSG;
    ROLLBACK;

  WHEN OTHERS THEN
    ROLLBACK;
    O_MSG := 'Erro ao excluir carro com placa '|| I_placa || ' = ' || SQLERRM;
  
END EXCLUI_CARRO;
/
