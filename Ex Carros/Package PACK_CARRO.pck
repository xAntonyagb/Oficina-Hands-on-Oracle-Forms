create or replace package PACK_CARRO is
  -- Author  : ANTONY
  -- Purpose : Gerenciamento das tabelas de tipo_carro e carro
  
  PROCEDURE INSERT_CARRO(
            i_Placa IN  VARCHAR2,
            i_Marca IN  VARCHAR2,
            i_Cor   IN  VARCHAR2,
            i_Ano   IN  NUMBER,
            i_Km    IN  VARCHAR2,
            i_Tipo  IN  NUMBER,
            O_MSG   OUT VARCHAR2);
            
  PROCEDURE EXCLUI_CARRO(
            I_placa IN NUMBER, 
            O_MSG OUT VARCHAR2);
                        
  PROCEDURE EXCLUI_TIPO_VEICULO(
            I_Tipo IN NUMBER, 
            O_MSG OUT VARCHAR2);
            
  PROCEDURE INSERT_TIPO_VEICULO(
            I_DS_TIPO    IN  VARCHAR2,
            I_QTD_PORTAS IN  NUMBER,
            I_QTD_RODAS  IN  NUMBER,
            I_DT_RECORD  IN  DATE DEFAULT SYSDATE,
            O_MSG        OUT VARCHAR2);
            
  PROCEDURE INSERT_TIPO_VEICULO(
            I_NR_CODIGO IN NUMBER,
            I_DS_TIPO IN VARCHAR2,
            I_QTD_PORTAS IN NUMBER,
            I_QTD_RODAS IN NUMBER,
            I_DT_RECORD IN DATE DEFAULT SYSDATE,
            O_MSG OUT VARCHAR2);
            
  PROCEDURE SAVE_CARRO(
            i_Placa IN VARCHAR2,
            i_Marca IN VARCHAR2,
            i_Cor IN VARCHAR2,
            i_Ano IN NUMBER,
            i_Km IN VARCHAR2,
            i_Tipo IN NUMBER,
            O_MSG OUT VARCHAR2);
  

end PACK_CARRO;
/
create or replace package body PACK_CARRO is

  PROCEDURE INSERT_CARRO(
            i_Placa IN  VARCHAR2,
            i_Marca IN  VARCHAR2,
            i_Cor   IN  VARCHAR2,
            i_Ano   IN  NUMBER,
            i_Km    IN  VARCHAR2,
            i_Tipo  IN  NUMBER,
            O_MSG   OUT VARCHAR2)
  IS
    v_count    NUMBER;
    e_geral    EXCEPTION;
    
  BEGIN
    O_MSG := 'Carro inserido com sucesso!';
    
    -- POPULANDO V_COUNT COM OS REGISTROS DO TIPO INFORMADO
    BEGIN 
      SELECT COUNT(*) INTO 
        v_count
      FROM 
        TIPO_VEICULO tv
      WHERE 
        tv.nr_codigo = i_Tipo;
    EXCEPTION
      WHEN OTHERS THEN
        v_count := 0;
    END;
    
    
    -- Se não tem o tipo -> exception
    IF NVL(v_count, 0) = 0 THEN
      O_MSG := 'Tipo não existente. Carro não foi inserido.';
      RAISE e_geral;
    END IF;
    

    -- POPULANDO V_COUNT COM OS REGISTROS DA PLACA INFORMADA
    BEGIN 
      SELECT COUNT(*)
      INTO v_count
      FROM CARRO
      WHERE CARRO.Nr_Placa = i_Placa;
    EXCEPTION
      WHEN OTHERS THEN
        v_count := 0;
    END;
    
    
    -- SE NÃO TEM PLACA -> PODE INSERIR
    IF NVL(v_count, 0) = 0 THEN
      INSERT INTO Carro
        (Nr_Placa, Ds_Marca, Ds_Cor, Dt_Ano, Vl_Km, Cd_Tipo)
      VALUES
        (i_Placa, i_Marca, i_Cor, i_Ano, i_Km, i_Tipo);
      
      COMMIT;
   
     -- SE TEM PLACA -> EXCEPTION
    ELSE
      O_MSG := 'Placa já existente. Carro não foi inserido.';
      RAISE e_geral;
    END IF;

  EXCEPTION
    WHEN e_geral THEN
      O_MSG := '[INSERT_CARRO]: '|| O_MSG;
      ROLLBACK;
     
    WHEN OTHERS THEN
      O_MSG := '[INSERT_CARRO]: Erro ao inserir o carro. ' || SQLERRM;
      ROLLBACK;
      
  END INSERT_CARRO;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  PROCEDURE EXCLUI_CARRO(
            I_placa IN  NUMBER, 
            O_MSG   OUT VARCHAR2)
  IS
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

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  PROCEDURE EXCLUI_TIPO_VEICULO(
            I_Tipo IN   NUMBER, 
            O_MSG  OUT VARCHAR2) 
  IS
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

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  PROCEDURE INSERT_TIPO_VEICULO(
            I_DS_TIPO    IN  VARCHAR2,
            I_QTD_PORTAS IN  NUMBER,
            I_QTD_RODAS  IN  NUMBER,
            I_DT_RECORD  IN  DATE DEFAULT SYSDATE,
            O_MSG        OUT VARCHAR2)
  IS
    V_SEQUENCIAL     NUMBER;
    
  BEGIN
    O_MSG := 'Tipo inserido com sucesso!';
    
    -- RESGATAR PRÓXIMO CÓDIGO DE TIPO
    BEGIN
      SELECT MAX(NR_CODIGO)+1 INTO 
        V_SEQUENCIAL
      FROM 
        TIPO_VEICULO;
    EXCEPTION
      WHEN OTHERS THEN
        V_SEQUENCIAL := 0;
    END;
    
    -- INSERIR
    INSERT INTO TIPO_VEICULO tv
      (tv.nr_codigo, tv.ds_tipo, tv.qtd_portas, tv.qtd_rodas, tv.dt_record)
    VALUES
      (V_SEQUENCIAL, I_DS_TIPO, I_QTD_PORTAS, I_QTD_RODAS, I_DT_RECORD);
      
    COMMIT;
    
  -- CASO OCORRA PROBLEMAS NA INSERÇÃO
  EXCEPTION    
    WHEN OTHERS THEN
      O_MSG := '[INSERT_TIPO_VEICULO]: Erro ao inserir o tipo: ' || SQLERRM;
      ROLLBACK;
  END INSERT_TIPO_VEICULO;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  PROCEDURE INSERT_TIPO_VEICULO(
            I_NR_CODIGO IN NUMBER,
            I_DS_TIPO IN VARCHAR2,
            I_QTD_PORTAS IN NUMBER,
            I_QTD_RODAS IN NUMBER,
            I_DT_RECORD IN DATE DEFAULT SYSDATE,
            O_MSG OUT VARCHAR2)
  IS
    V_COUNT NUMBER;
    E_GERAL EXCEPTION;
    
  BEGIN
    O_MSG := 'Tipo inserido com sucesso!';
    
    -- POPULANDO V_COUNT (VALIDAÇÃO)
    BEGIN 
      SELECT COUNT(*)
      INTO V_COUNT
      FROM TIPO_VEICULO tv
      WHERE tv.nr_codigo = I_NR_CODIGO;
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;
    
    -- CASO O TIPO JÁ NÃO ESTIVER REGISTRADO -> INSERIR
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
      O_MSG := '[INSERT_TIPO_VEICULO]: Tipo já existente. Tipo não foi inserido: ' || I_NR_CODIGO;
      ROLLBACK;
    WHEN OTHERS THEN
      O_MSG := '[INSERT_TIPO_VEICULO]: Erro ao inserir o tipo: ' || SQLERRM;
      ROLLBACK;
  END INSERT_TIPO_VEICULO;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  PROCEDURE SAVE_CARRO(
            i_Placa IN VARCHAR2,
            i_Marca IN VARCHAR2,
            i_Cor IN VARCHAR2,
            i_Ano IN NUMBER,
            i_Km IN VARCHAR2,
            i_Tipo IN NUMBER,
            O_MSG OUT VARCHAR2)
  IS
    v_count_tp NUMBER;
    e_geral EXCEPTION;
    
  BEGIN
    
    -- bloco de validações null
   /*VALIDAÇÃO COR*/
    IF i_Cor IS NULL THEN
      O_MSG := 'A cor do veiculo precisa ser preenchida.';
      RAISE E_GERAL;
    END IF;
      
    /*VALIDAÇÃO MARCA*/
    IF i_Marca IS NULL THEN
      O_MSG := 'A marca do veiculo precisa ser preenchida.';
      RAISE E_GERAL;
    END IF;
      
    /*VALIDAÇÃO ANO*/
    IF i_Ano IS NULL THEN
      O_MSG := 'O ano do veiculo precisa ser preenchido.';
      RAISE E_GERAL;
    END IF;
    
    /*VALIDAÇÃO MODELO*/
      IF i_Tipo IS NULL THEN
        O_MSG := 'O modelo do veiculo precisa ser preenchido.';
        RAISE E_GERAL;
      END IF;
    -- fim do bloco
    
    -- VALIDAÇÃO CASO O ANO SEJA SUPERIOR DO ATUAL 
    IF NVL(i_Ano, 0) > TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) THEN
        O_MSG := 'O ano do carro não pode ser superior ao ano seguinte ao atual!';
        RAISE E_GERAL;
    END IF;

    -- POPULANDO V_COUNT_TP
    BEGIN 
      SELECT COUNT(*)
      INTO v_count_tp
      FROM TIPO_VEICULO tv
      WHERE tv.nr_codigo = i_Tipo;
    EXCEPTION
      WHEN OTHERS THEN
        v_count_tp := 0;
    END;
    
    -- Se não tem o tipo em registro -> exception
    IF NVL(v_count_tp, 0) = 0 THEN
      O_MSG := 'Tipo não existente. Carro não foi inserido ou atualizado.';
      RAISE e_geral;
    END IF;
    
    -- OPERAÇÃO SAVE
    BEGIN
      -- TENTAR FAZER O INSERT
      INSERT INTO Carro
        (Nr_Placa, Ds_Marca, Ds_Cor, Dt_Ano, Vl_Km, Cd_Tipo)
      VALUES
        (i_Placa, i_Marca, i_Cor, i_Ano, i_Km, i_Tipo);
      
      COMMIT;
      O_MSG := 'Carro inserido com sucesso!';

    -- CASO JÁ EXISTA -> UPDATE  
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          UPDATE Carro
          SET Ds_Marca =    NVL(i_Marca, Ds_Marca),
              Ds_Cor =      NVL(i_Cor, Ds_Cor),
              Dt_Ano =      NVL(i_Ano, Dt_Ano),
              Vl_Km =       NVL(i_Km, Vl_Km),
              Cd_Tipo =     NVL(i_Tipo, Cd_Tipo)
          WHERE Nr_Placa =  i_Placa;
          
          COMMIT;
          O_MSG := 'Carro atualizado com sucesso!';
          
        -- CASO OCORRA PROBLEMAS NO UPDATE
        EXCEPTION
          WHEN OTHERS THEN
            O_MSG := 'Erro ao atualizar o carro.';
            RAISE e_geral;
        END;
    END;

  EXCEPTION
    WHEN e_geral THEN
      ROLLBACK;
      O_MSG := '[SAVE_CARRO]: '|| O_MSG;
      
    WHEN OTHERS THEN
      ROLLBACK;
      O_MSG := '[SAVE_CARRO]: Erro ao inserir ou atualizar o carro - ' || SQLERRM;

  END;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
end PACK_CARRO;
/
