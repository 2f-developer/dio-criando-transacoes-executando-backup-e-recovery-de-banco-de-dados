-- Estado esperado depois das partes 1 e 2.
USE ecommerce;

DELIMITER $$

CREATE PROCEDURE espera_erro(IN descricao VARCHAR(200), IN comando TEXT)
BEGIN
  DECLARE falhou BOOLEAN DEFAULT FALSE;
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET falhou = TRUE;
    SET @comando = comando;
    PREPARE stmt FROM @comando;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END;
  IF NOT falhou THEN
    SET @msg = CONCAT('FALHOU (deveria ser recusado): ', descricao);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;
  SELECT CONCAT('ok  ', descricao) AS resultado;
END$$

CREATE PROCEDURE espera_igual(IN descricao VARCHAR(200), IN obtido VARCHAR(100), IN esperado VARCHAR(100))
BEGIN
  IF NOT (obtido <=> esperado) THEN
    SET @msg = CONCAT('FALHOU: ', descricao, ' (obtido ', COALESCE(obtido, 'NULL'), ', esperado ', COALESCE(esperado, 'NULL'), ')');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @msg;
  END IF;
  SELECT CONCAT('ok  ', descricao) AS resultado;
END$$

DELIMITER ;

CALL espera_igual('transação confirmada baixou o estoque do cabo', (SELECT estoque FROM produto WHERE id = 3), '98');
CALL espera_igual('ROLLBACK desfez o reajuste errado', (SELECT preco FROM produto WHERE id = 1), '249.90');
CALL espera_igual('pedido com cupom válido tem 10% de desconto', (SELECT CONCAT(cupom, ' ', desconto) FROM pedido WHERE id = 2), 'BEMVINDO10 24.99');
CALL espera_igual('cupom válido teve um uso consumido', (SELECT usos_restantes FROM cupom WHERE codigo = 'BEMVINDO10'), '99');
CALL espera_igual('cupom vencido: pedido gravado sem desconto (rollback parcial)', (SELECT CONCAT(COALESCE(cupom, '-'), ' ', desconto) FROM pedido WHERE id = 3), '- 0.00');
CALL espera_igual('cupom vencido não perdeu uso', (SELECT usos_restantes FROM cupom WHERE codigo = 'VENCIDO20'), '50');
CALL espera_igual('estoque insuficiente não gravou pedido (rollback total)', (SELECT COUNT(*) FROM pedido), '3');
CALL espera_igual('estoque do teclado intacto', (SELECT estoque FROM produto WHERE id = 2), '3');
CALL espera_erro('erro de banco dentro da procedure é repassado',
  "CALL registrar_pedido(999, 1, 1, NULL, @id, @msg)");
CALL espera_igual('e nada fica gravado depois do erro', (SELECT COUNT(*) FROM pedido), '3');
CALL espera_igual('o estoque também volta depois do erro', (SELECT estoque FROM produto WHERE id = 1), '8');

DROP PROCEDURE espera_erro;
DROP PROCEDURE espera_igual;
SELECT 'todas as verificações passaram' AS resultado;
