create or replace package PKG_ITEMVENDA is

  PROCEDURE SAVE_ITEM_VENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            I_VL_UNITPROD   IN ITEMVENDA.VL_UNITPROD%TYPE,
            I_QT_ADQUIRIDA  IN ITEMVENDA.QT_ADQUIRIDA%TYPE,
            I_DT_RECORD     IN ITEMVENDA.DT_RECORD%TYPE DEFAULT SYSDATE,
            O_OPERACAO      OUT CHAR,
            O_ERROR_MSG     OUT VARCHAR2);
            
  PROCEDURE EXCLUIR_ITEM_VENDA(
            I_CD_VENDA    IN ITEMVENDA.CD_VENDA%TYPE, 
            I_CD_PRODUTO  IN ITEMVENDA.CD_PRODUTO%TYPE,
            O_ERROR_MSG   OUT VARCHAR2);
            
  PROCEDURE EXCLUIR_ITEM_VENDA_BY_VENDA(
            I_CD_VENDA    IN ITEMVENDA.CD_VENDA%TYPE,
            O_ERROR_MSG   OUT VARCHAR2);
            
  FUNCTION CALCULAR_SUBTOTAL(
      I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
      I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE)
  RETURN NUMBER;

end PKG_ITEMVENDA;
/
CREATE OR REPLACE PACKAGE BODY PKG_ITEMVENDA IS

  /* Para inserir e fazer update em itens de venda */
  PROCEDURE SAVE_ITEM_VENDA(
            I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
            I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE,
            I_VL_UNITPROD   IN ITEMVENDA.VL_UNITPROD%TYPE,
            I_QT_ADQUIRIDA  IN ITEMVENDA.QT_ADQUIRIDA%TYPE,
            I_DT_RECORD     IN ITEMVENDA.DT_RECORD%TYPE DEFAULT SYSDATE,
            O_OPERACAO      OUT CHAR,
            O_ERROR_MSG     OUT VARCHAR2)
  IS
    V_COUNT NUMBER;
    V_POS   NUMBER;
    E_GERAL EXCEPTION;
  BEGIN
    
    -- VALIDA��ES
    /* VALIDA��O VENDA */
    IF I_CD_VENDA IS NULL THEN
      O_ERROR_MSG := 'C�digo da venda n�o informado';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(I_CD_VENDA)) > 15 THEN
      O_ERROR_MSG := 'C�digo da venda n�o pode exceder 15 d�gitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICAR SE A VENDA EXISTE
    BEGIN 
      SELECT COUNT(*)
      INTO   V_COUNT
      FROM   VENDA
      WHERE  CD_VENDA = I_CD_VENDA;
      
      IF V_COUNT = 0 THEN
        O_ERROR_MSG := 'A venda informada n�o existe';
        RAISE E_GERAL;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        O_ERROR_MSG := 'A venda informada n�o existe';
        RAISE E_GERAL;
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao verificar a venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

    /* VALIDA��O PRODUTO */
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'C�digo do produto n�o informado';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(I_CD_PRODUTO)) > 10 THEN
      O_ERROR_MSG := 'C�digo do produto n�o pode exceder 10 d�gitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICAR SE O PRODUTO EXISTE
    BEGIN 
      SELECT COUNT(*)
      INTO   V_COUNT
      FROM   PRODUTO
      WHERE  CD_PRODUTO = I_CD_PRODUTO;
      
      IF V_COUNT = 0 THEN
        O_ERROR_MSG := 'O produto informado n�o existe';
        RAISE E_GERAL;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        O_ERROR_MSG := 'O produto informado n�o existe';
        RAISE E_GERAL;
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao verificar o produto: ' || SQLERRM;
        RAISE E_GERAL;
    END;

    /* VALIDA��O VALOR UNIT */
    IF I_VL_UNITPROD IS NULL THEN
      O_ERROR_MSG := 'Valor unit�rio do produto n�o informado';
      RAISE E_GERAL;
    END IF;
    
    IF I_VL_UNITPROD <= 0 THEN
      O_ERROR_MSG := 'Valor unit�rio inv�lido. Informe um valor maior que zero';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(TRUNC(I_VL_UNITPROD))) > 15 THEN
      O_ERROR_MSG := 'Valor unit�rio inv�lido. Informe um valor com at� 15 casas inteiras';
      RAISE E_GERAL;
    END IF;

    -- Verificar o tamanho da parte decimal
    V_POS := INSTR(TO_CHAR(I_VL_UNITPROD), '.');
    IF V_POS > 0 THEN
      -- Corta a string a partir da virgula utilizando V_POS para verificar o tamanho
      IF LENGTH(SUBSTR(TO_CHAR(I_VL_UNITPROD), V_POS + 1)) > 2 THEN
        O_ERROR_MSG := 'Valor unit�rio inv�lido. Informe um valor com at� 2 casas decimais';
        RAISE E_GERAL;
      END IF;
    END IF;

    /* VALIDA��O QUANTIDADE ADQUIRIDA */
    IF I_QT_ADQUIRIDA IS NULL THEN
      O_ERROR_MSG := 'Quantidade adquirida n�o informada';
      RAISE E_GERAL;
    END IF;

    IF I_QT_ADQUIRIDA <= 0 THEN
      O_ERROR_MSG := 'Quantidade adquirida inv�lida. Informe um valor maior que zero';
      RAISE E_GERAL;
    END IF;

    IF LENGTH(TO_CHAR(TRUNC(I_QT_ADQUIRIDA))) > 15 THEN
      O_ERROR_MSG := 'Quantidade adquirida inv�lida. Informe uma quantidade com no m�ximo 15 casas inteiras';
      RAISE E_GERAL;
    END IF;

    -- Verificar o tamanho da parte decimal
    V_POS := INSTR(TO_CHAR(I_QT_ADQUIRIDA), '.');
    IF V_POS > 0 THEN
      -- Corta a string a partir da virgula utilizando V_POS para verificar o tamanho
      IF LENGTH(SUBSTR(TO_CHAR(I_QT_ADQUIRIDA), V_POS + 1)) > 2 THEN
        O_ERROR_MSG := 'Quantidade adquirida inv�lida. Informe uma quantidade com at� 2 casas decimais';
        RAISE E_GERAL;
      END IF;
    END IF;

    /* VALIDA��O DATA */
    IF I_DT_RECORD IS NULL THEN
      O_ERROR_MSG := 'DT_RECORD n�o informada';
      RAISE E_GERAL;
    END IF;

    -- Verificar se a data est� no formato errado ou � futura
    DECLARE
      V_VALIDACAO_DATE DATE;
    BEGIN
      V_VALIDACAO_DATE := TO_DATE(TO_CHAR(I_DT_RECORD, 'DD/MM/YYYY'), 'DD/MM/YYYY');
      
      IF V_VALIDACAO_DATE > SYSDATE THEN
        O_ERROR_MSG := 'DT_RECORD n�o pode ser uma data futura';
        RAISE E_GERAL;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'DT_RECORD inv�lida. Informe no formato DD/MM/YYYY';
        RAISE E_GERAL;
    END;

    /* OPERA��O SAVE */
    BEGIN
      O_OPERACAO := 'I';
      -- TENTAR FAZER O INSERT
      INSERT INTO ITEMVENDA
        (CD_VENDA, CD_PRODUTO, VL_UNITPROD, QT_ADQUIRIDA, DT_RECORD)
      VALUES
        (I_CD_VENDA, I_CD_PRODUTO, I_VL_UNITPROD, I_QT_ADQUIRIDA, I_DT_RECORD);
      
      COMMIT;
    
    EXCEPTION
      -- CASO J� EXISTA -> UPDATE  
      WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
          O_OPERACAO := 'U';
          UPDATE ITEMVENDA
          SET 
              VL_UNITPROD = I_VL_UNITPROD,
              QT_ADQUIRIDA = I_QT_ADQUIRIDA,
              DT_RECORD = I_DT_RECORD
          WHERE CD_VENDA = I_CD_VENDA AND CD_PRODUTO = I_CD_PRODUTO;
          
          COMMIT;
          
        -- CASO OCORRA PROBLEMAS NO UPDATE
        EXCEPTION
          WHEN OTHERS THEN
            O_ERROR_MSG := 'Erro ao atualizar o item de venda: ' || SQLERRM;
            RAISE E_GERAL;
        END;

      -- OUTROS ERROS DE INSERT
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao inserir o item de venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[SAVE_ITEM_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[SAVE_ITEM_VENDA] Erro ao salvar o item de venda: ' || SQLERRM;
      ROLLBACK;
  END SAVE_ITEM_VENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------

  /* Para excluir itens de venda */
  PROCEDURE EXCLUIR_ITEM_VENDA(
            I_CD_VENDA    IN ITEMVENDA.CD_VENDA%TYPE, 
            I_CD_PRODUTO  IN ITEMVENDA.CD_PRODUTO%TYPE,
            O_ERROR_MSG   OUT VARCHAR2) 
  IS
    V_COUNT   NUMBER;
    E_GERAL   EXCEPTION;
  
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

    -- VALIDA��O CD_PRODUTO
    IF I_CD_PRODUTO IS NULL THEN
      O_ERROR_MSG := 'C�digo do produto n�o informado';
      RAISE E_GERAL;
    END IF;
    
    IF LENGTH(TO_CHAR(I_CD_PRODUTO)) > 10 THEN
      O_ERROR_MSG := 'C�digo do produto n�o pode exceder 10 d�gitos';
      RAISE E_GERAL;
    END IF;

    -- VERIFICANDO SE O ITEM DE VENDA EXISTE
    BEGIN 
      SELECT COUNT(*)
      INTO   V_COUNT
      FROM   ITEMVENDA
      WHERE  CD_VENDA = I_CD_VENDA AND CD_PRODUTO = I_CD_PRODUTO;
      
      IF V_COUNT = 0 THEN
        O_ERROR_MSG := 'O item de venda informado n�o existe';
        RAISE E_GERAL; 
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao verificar o item de venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

    -- EXCLUINDO O ITEM DE VENDA
    BEGIN
      DELETE FROM ITEMVENDA
      WHERE CD_VENDA = I_CD_VENDA AND CD_PRODUTO = I_CD_PRODUTO;
      
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir o item de venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;
  EXCEPTION
    WHEN e_geral THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA] Erro ao excluir a venda: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_ITEM_VENDA;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para excluir todos os itens de venda de uma venda espec�fica */
  PROCEDURE EXCLUIR_ITEM_VENDA_BY_VENDA(
            I_CD_VENDA    IN ITEMVENDA.CD_VENDA%TYPE,
            O_ERROR_MSG   OUT VARCHAR2)
  IS
    V_COUNT   NUMBER;
    E_GERAL   EXCEPTION;
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
      SELECT COUNT(*)
      INTO   V_COUNT
      FROM   VENDA
      WHERE  CD_VENDA = I_CD_VENDA;
      
      IF V_COUNT = 0 THEN
        O_ERROR_MSG := 'A venda informada n�o existe';
        RAISE E_GERAL;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        O_ERROR_MSG := 'A venda informada n�o existe';
        RAISE E_GERAL;
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao verificar a venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;

    -- EXCLUINDO OS ITENS DE VENDA DA VENDA ESPEC�FICA
    BEGIN 
      DELETE FROM ITEMVENDA
      WHERE CD_VENDA = I_CD_VENDA;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        O_ERROR_MSG := 'Erro ao excluir os itens de venda da venda: ' || SQLERRM;
        RAISE E_GERAL;
    END;
    
  EXCEPTION
    WHEN E_GERAL THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA_BY_VENDA] ' || O_ERROR_MSG;
      ROLLBACK;
    
    WHEN OTHERS THEN
      O_ERROR_MSG := '[EXCLUIR_ITEM_VENDA_BY_VENDA] Erro ao excluir os itens de venda pela venda: ' || SQLERRM;
      ROLLBACK;
  END EXCLUIR_ITEM_VENDA_BY_VENDA;

  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
  /* Para retornar o valor calculado do subtotal de um ItemVenda */
  FUNCTION CALCULAR_SUBTOTAL(
      I_CD_VENDA      IN ITEMVENDA.CD_VENDA%TYPE,
      I_CD_PRODUTO    IN ITEMVENDA.CD_PRODUTO%TYPE)
  RETURN NUMBER
  IS
      V_SUBTOTAL NUMBER := 0;
  BEGIN
      SELECT VL_UNITPROD * QT_ADQUIRIDA
      INTO V_SUBTOTAL
      FROM ITEMVENDA
      WHERE CD_VENDA = I_CD_VENDA AND CD_PRODUTO = I_CD_PRODUTO;

      RETURN V_SUBTOTAL;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
          RETURN 0; -- Retorna 0 se nada encontrado
      WHEN OTHERS THEN
          RETURN -1; -- Retorna -1 caso erro
  END CALCULAR_SUBTOTAL;
  
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  
END PKG_ITEMVENDA;
/
