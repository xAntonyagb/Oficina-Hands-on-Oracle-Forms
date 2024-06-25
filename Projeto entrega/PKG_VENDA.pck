CREATE OR REPLACE PACKAGE PKG_VENDA IS

  PROCEDURE EXCLUIR_VENDA(
            I_CD_VENDA      IN VENDA.CD_VENDA%TYPE, 
            O_ERROR_MSG     OUT VARCHAR2);
            
  PROCEDURE SAVE_VENDA(
            I_CD_VENDA      IN VENDA.CD_VENDA%TYPE, 
            I_VL_TOTAL      IN VENDA.VL_TOTAL%TYPE, 
            I_QT_TOTAL      IN VENDA.QT_TOTAL%TYPE, 
            I_NR_CPFCLIENTE IN VENDA.NR_CPFCLIENTE%TYPE,
            I_DT_VENDA      IN VENDA.DT_VENDA%TYPE DEFAULT SYSDATE,
            O_OERACAO       OUT CHAR,
            O_ERROR_MSG     OUT VARCHAR2);

END PKG_VENDA;
/
CREATE OR REPLACE PACKAGE BODY PKG_VENDA IS

  /* Auxiliares */
  V_COUNT   NUMBER;
  E_GERAL   EXCEPTION;
    
  /* Para inserir e fazer update em vendas */
  PROCEDURE SAVE_VENDA(
            I_CD_VENDA      IN VENDA.CD_VENDA%TYPE, 
            I_VL_TOTAL      IN VENDA.VL_TOTAL%TYPE, 
            I_QT_TOTAL      IN VENDA.QT_TOTAL%TYPE, 
            I_NR_CPFCLIENTE IN VENDA.NR_CPFCLIENTE%TYPE,
            I_DT_VENDA      IN VENDA.DT_VENDA%TYPE DEFAULT SYSDATE,
            O_OERACAO       OUT CHAR,
            O_ERROR_MSG     OUT VARCHAR2)
  IS
    V_POS   NUMBER;
  BEGIN
    
    -- VALIDA��ES
    /* VALIDA��O CD_VENDA */
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'C�digo da venda n�o informado';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(I_CD_VENDA)) > 15 THEN
      O_ERROR_MSG := 'C�digo da venda n�o pode exceder 15 d�gitos';
      RAISE E_GERAL;
    END IF;

    /* VALIDA��O VALOR TOTAL */
    IF I_VL_TOTAL IS NULL THEN
      O_ERROR_MSG := 'Valor total da venda n�o informado';
      RAISE E_GERAL;
    END IF;
    
    IF I_VL_TOTAL <= 0 THEN
      O_ERROR_MSG := 'Valor total inv�lido. Informe um valor maior que zero';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(TRUNC(I_VL_TOTAL))) > 15 THEN
      O_ERROR_MSG := 'Valor total inv�lido. Informe um valor com at� 15 casas inteiras';
      RAISE E_GERAL;
    END IF;
    
    -- Verificar o tamanho da parte decimal
    V_POS := INSTR(TO_CHAR(I_VL_TOTAL), ','); -- Retorna pos da virgula
    IF V_POS > 0 THEN
      -- Corta a string a partir da virgula utilizando V_POS para verificar o tamanho
      IF LENGTH(SUBSTR(TO_CHAR(I_VL_TOTAL), V_POS + 1)) > 2 THEN
        O_ERROR_MSG := 'Valor total inv�lido. Informe um valor com at� 2 casas decimais';
        RAISE E_GERAL;
      END IF;
    END IF;

    /* VALIDA��O QUANTIDADE TOTAL */
    IF I_QT_TOTAL IS NULL THEN
      O_ERROR_MSG := 'Quantidade total da venda n�o informada';
      RAISE E_GERAL;
    END IF;

    IF I_QT_TOTAL <= 0 THEN
      O_ERROR_MSG := 'Quantidade total inv�lida. Informe um valor maior que zero';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(TRUNC(I_QT_TOTAL))) > 15 THEN
      O_ERROR_MSG := 'Quantidade total inv�lida. Informe uma quantidade com no m�ximo 15 casas inteiras';
      RAISE E_GERAL;
    END IF;
    
    -- Verificar o tamanho da parte decimal
    V_POS := INSTR(TO_CHAR(I_QT_TOTAL), ','); -- Retorna pos da virgula
    IF V_POS > 0 THEN
      -- Corta a string a partir da virgula utilizando V_POS para verificar o tamanho
      IF LENGTH(SUBSTR(TO_CHAR(I_QT_TOTAL), V_POS + 1)) > 2 THEN
        O_ERROR_MSG := 'Quantidade total inv�lida. Informe uma quantidade com no m�ximo 2 casas decimais';
        RAISE E_GERAL;
      END IF;
    END IF;

    /* VALIDA��O CLIENTE */
    IF I_NR_CPFCLIENTE IS NULL THEN
      O_ERROR_MSG := 'CPF do cliente n�o informado';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(I_NR_CPFCLIENTE) != 11 THEN
      O_ERROR_MSG := 'CPF do cliente deve ter 11 caracteres';
      RAISE E_GERAL;
    END IF;
    
    -- Verificar se existe registro do cliente
    BEGIN
      SELECT 
        COUNT(*)
      INTO   
        V_COUNT
      FROM   
        CLIENTE
      WHERE  
        NR_CPF = I_NR_CPFCLIENTE;
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;
      
    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'O cliente informado n�o existe';
      RAISE E_GERAL;
    END IF;
      
    /* VALIDA��O DATA */
    IF I_DT_VENDA IS NULL THEN
      O_ERROR_MSG := 'Data da venda n�o informada';
      RAISE E_GERAL;
    END IF;

    -- Verificar se a data est� no formato errado ou � futura
    DECLARE
      V_VALIDACAO_DATE DATE;
    BEGIN
      V_VALIDACAO_DATE := TO_DATE(TO_CHAR(I_DT_VENDA, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      
      IF V_VALIDACAO_DATE > SYSDATE THEN
        O_ERROR_MSG := 'Data da venda n�o pode ser uma data futura';
        RAISE E_GERAL;
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Data da venda inv�lida. Informe no formato DD/MM/YYYY';
        RAISE E_GERAL;
    END;


    -- OPERA��O SAVE
    BEGIN
      O_OERACAO := 'I';
      -- TENTAR FAZER O INSERT
      INSERT INTO VENDA
        (CD_VENDA, VL_TOTAL, QT_TOTAL, NR_CPFCLIENTE, DT_VENDA)
      VALUES
        (I_CD_VENDA, I_VL_TOTAL, I_QT_TOTAL, I_NR_CPFCLIENTE, I_DT_VENDA);
      
      COMMIT;
    
    EXCEPTION
      -- CASO J� EXISTA -> UPDATE  
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          O_OERACAO := 'U';
          
          UPDATE 
            VENDA
          SET 
            VL_TOTAL = I_VL_TOTAL,
            QT_TOTAL = I_QT_TOTAL,
            NR_CPFCLIENTE = I_NR_CPFCLIENTE,
            DT_VENDA = I_DT_VENDA
          WHERE 
            CD_VENDA = I_CD_VENDA;
          COMMIT;
          
        -- CASO OCORRA PROBLEMAS NO UPDATE
        EXCEPTION
          WHEN OTHERS THEN
            O_ERROR_MSG := 'Erro ao atualizar a venda: ' || SQLERRM;
            RAISE E_GERAL;
        END;

      -- OUTROS ERROS DE INSERT
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao inserir a venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[SAVE_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[SAVE_VENDA] Erro ao salvar a venda: ' || SQLERRM;
      ROLLBACK;
  END SAVE_VENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Para excluir vendas */
  PROCEDURE EXCLUIR_VENDA(
            I_CD_VENDA    IN VENDA.CD_VENDA%TYPE, 
            O_ERROR_MSG   OUT VARCHAR2) 
  IS
  BEGIN

    -- VALIDA��O CD_VENDA
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'C�digo da venda n�o informado';
      RAISE E_GERAL;
    END IF;
    
    IF LENGTH(TO_CHAR(I_CD_VENDA)) > 15 THEN
      O_ERROR_MSG := 'C�digo da venda n�o pode exceder 15 d�gitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE A VENDA EXISTE
    BEGIN 
      SELECT 
        COUNT(*)
      INTO   
        V_COUNT
      FROM   
        VENDA
      WHERE  
        CD_VENDA = I_CD_VENDA;
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;

    IF V_COUNT = 0 THEN
      O_ERROR_MSG := 'Essa venda n�o existe';
      RAISE E_GERAL; 
    END IF;
    
    -- EXCLUIR OS ITENS VENDA DESSA VENDA PRIMEIRO
    BEGIN
       PKG_ITEMVENDA.EXCLUIR_ITEM_VENDA_BY_VENDA(
                     I_CD_VENDA => I_CD_VENDA, 
                     O_ERROR_MSG => O_ERROR_MSG);
                     
       IF O_ERROR_MSG IS NOT NULL THEN
         RAISE E_GERAL;
       END IF;
    END;

    -- EXCLUIR A VENDA
    BEGIN
      DELETE FROM 
        VENDA
      WHERE 
        CD_VENDA = I_CD_VENDA;
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir a venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[EXCLUIR_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_VENDA] Erro ao excluir a venda: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_VENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  PROCEDURE BUSCAR_TOTAIS(
      I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
      O_VL_TOTAL      OUT NUMBER,
      O_QT_TOTAL      OUT NUMBER,
      O_ERROR_MSG     OUT VARCHAR2
  )
  IS
  BEGIN
    O_VL_TOTAL := 0;
    O_QT_TOTAL := 0;

    /* VALIDA��O VENDA */
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'C�digo da venda n�o informado';
      RETURN;
    END IF;

    -- Verificando se a venda existe
    BEGIN 
      SELECT 
        COUNT(*)
      INTO 
        V_COUNT
      FROM 
        VENDA
      WHERE 
        CD_VENDA = I_CD_VENDA;
      COMMIT;
      
    EXCEPTION
      WHEN OTHERS THEN
        V_COUNT := 0;
    END;
          
    IF V_COUNT = 0 THEN
        O_ERROR_MSG := 'A venda informada n�o existe';
        RETURN;
    END IF;
      
    /* Busca valor total e quantidade total de itens da venda */
    SELECT 
      NVL(SUM(IV.VL_UNITPROD * IV.QT_ADQUIRIDA), 0), 
      NVL(SUM(IV.QT_ADQUIRIDA), 0)
    INTO 
      O_VL_TOTAL, 
      O_QT_TOTAL
    FROM 
      ITEMVENDA IV
    WHERE 
      IV.CD_VENDA = I_CD_VENDA;
    COMMIT;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ROLLBACK;
      O_ERROR_MSG := '[BUSCAR_TOTAIS] Nenhum item encontrado para a venda informada';
    WHEN OTHERS THEN
      ROLLBACK;
      O_ERROR_MSG := '[BUSCAR_TOTAIS] Erro ao buscar totais: ' || SQLERRM;
      
  END BUSCAR_TOTAIS;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
END PKG_VENDA;
/
