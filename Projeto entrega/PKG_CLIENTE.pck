CREATE OR REPLACE PACKAGE PKG_CLIENTE IS

  PROCEDURE SAVE_CLIENTE(
            I_NR_CPF          IN CLIENTE.NR_CPF%TYPE, 
            I_NM_CLIENTE      IN CLIENTE.NM_CLIENTE%TYPE, 
            I_DT_NASCIMENTO   IN CLIENTE.DT_NASCIMENTO%TYPE,
            O_OERACAO         OUT CHAR,
            O_ERROR_MSG       OUT VARCHAR2);
      
  PROCEDURE EXCLUIR_CLIENTE(
            I_NR_CPF          IN CLIENTE.NR_CPF%TYPE, 
            I_FORCE_DELETE    IN CHAR DEFAULT 'S',
            O_ERROR_MSG       OUT VARCHAR2);

END PKG_CLIENTE;
/
CREATE OR REPLACE package body PKG_CLIENTE IS

  /* Auxiliares */
  V_COUNT   NUMBER;
  E_GERAL   EXCEPTION;

  /* Para inserir e fazer update em clientes */
  PROCEDURE SAVE_CLIENTE(
            I_NR_CPF          IN CLIENTE.NR_CPF%TYPE, 
            I_NM_CLIENTE      IN CLIENTE.NM_CLIENTE%TYPE, 
            I_DT_NASCIMENTO   IN CLIENTE.DT_NASCIMENTO%TYPE,
            O_OERACAO         OUT CHAR,
            O_ERROR_MSG       OUT VARCHAR2)
  IS
  BEGIN
    
    -- VALIDAÇÕES
    /* VALIDAÇÃO CPF */
    IF I_NR_CPF IS NULL THEN
      O_ERROR_MSG := 'CPF não informado';
      RAISE e_geral;
    END IF;
    
    IF LENGTH(I_NR_CPF) != 11 THEN
      O_ERROR_MSG := 'Informe um CPF com 11 digitos';
      RAISE e_geral;
    END IF;

    /* VALIDAÇÃO NOME */
    IF I_NM_CLIENTE IS NULL THEN
      O_ERROR_MSG := 'Nome do cliente não informado';
      RAISE e_geral;
    END IF;
    
    IF LENGTH(I_NM_CLIENTE) > 100 THEN
      O_ERROR_MSG := 'Informe um nome com menos de 100 carácteres';
      RAISE e_geral;
    END IF;

    /* VALIDAÇÃO DATA DE NASCIMENTO */
    IF I_DT_NASCIMENTO IS NULL THEN
      O_ERROR_MSG := 'Data de nascimento não informada';
      RAISE e_geral;
    END IF;

    -- Verificar se a data está no formato errado ou é futura
    DECLARE
      V_VALIDACAO_DATE DATE;
    BEGIN
      V_VALIDACAO_DATE := TO_DATE(TO_CHAR(I_DT_NASCIMENTO, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      
      IF V_VALIDACAO_DATE > SYSDATE THEN
        O_ERROR_MSG := 'Data de nacimento não pode ser uma data futura';
        RAISE E_GERAL;
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Data de nacimento inválida. Informe no formato DD/MM/YYYY';
        RAISE E_GERAL;
    END;


    -- OPERAÇÃO SAVE
    BEGIN
      O_OERACAO := 'I';
      
      -- TENTAR FAZER O INSERT
      INSERT INTO CLIENTE
        (NR_CPF,NM_CLIENTE,DT_NASCIMENTO)
      VALUES
        (I_NR_CPF,I_NM_CLIENTE,I_DT_NASCIMENTO);
      COMMIT;
    
    EXCEPTION
      -- CASO JÁ EXISTA -> UPDATE  
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          O_OERACAO := 'U';
          
          UPDATE 
            CLIENTE
          SET 
            NM_CLIENTE =    I_NM_CLIENTE,
            DT_NASCIMENTO = I_DT_NASCIMENTO
          WHERE 
            NR_CPF = I_NR_CPF;
          COMMIT;
          
        -- CASO OCORRA PROBLEMAS NO UPDATE
        EXCEPTION
          WHEN OTHERS THEN
            O_ERROR_MSG := 'Erro ao atualizar o cliente: ' || SQLERRM;
            RAISE e_geral;
        END;

      -- OUTROS ERROS DE INSERT
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao inserir o cliente: ' || SQLERRM;
        RAISE e_geral;
    END;

  EXCEPTION
    WHEN e_geral THEN
      O_ERROR_MSG := '[SAVE_CLIENTE] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[SAVE_CLIENTE] Erro ao salvar o cliente: ' || SQLERRM;
      ROLLBACK;
  END SAVE_CLIENTE;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Para excluir clientes */
  PROCEDURE EXCLUIR_CLIENTE(
            I_NR_CPF        IN CLIENTE.NR_CPF%TYPE, 
            I_FORCE_DELETE  IN CHAR DEFAULT 'S',
            O_ERROR_MSG     OUT VARCHAR2) 
  IS
  BEGIN

    -- VALIDAÇÃO CPF
    IF I_NR_CPF IS NULL THEN
      O_ERROR_MSG := 'CPF não informado';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE O CLIENTE EXISTE
    BEGIN 
      SELECT 
        COUNT(*)
      INTO  
        V_COUNT
      FROM   
        CLIENTE
      WHERE  
        NR_CPF = I_NR_CPF;
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;

    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'Esse cliente não existe';
      RAISE E_GERAL; 
    END IF;

    -- VERIFICAR SE DEVE FAZER VALIDAÇÃO DE FK
    IF I_FORCE_DELETE != 'S' THEN
      -- VERIFICANDO SE O CLIENTE ESTÁ PRESENTE EM ALGUMA VENDA 
      BEGIN 
        SELECT 
          COUNT(*)
        INTO   
          V_COUNT
        FROM   
          VENDA
        WHERE  
          NR_CPFCLIENTE = I_NR_CPF;
        COMMIT;
        
      EXCEPTION
        WHEN OTHERS THEN
          V_COUNT := 0;
      END;

      IF V_COUNT > 0 THEN
        O_ERROR_MSG := 'Esse cliente está presente em uma ou mais vendas';
        RAISE e_geral;
      END IF;
    END IF;


    -- EXCLUINDO O CLIENTE
    BEGIN
      UPDATE 
        CLIENTE
      SET 
        ST_ATIVO = 'N'
      WHERE 
        NR_CPF = I_NR_CPF;
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir o cliente: ' || SQLERRM;
        RAISE e_geral;
    END;

  EXCEPTION
    WHEN e_geral THEN
      O_ERROR_MSG := '[EXCLUIR_CLIENTE] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_CLIENTE] Erro ao excluir o cliente: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_CLIENTE;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
    
END PKG_CLIENTE;
/
