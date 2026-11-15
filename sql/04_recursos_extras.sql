-- Recursos que o backup precisa levar junto: um evento no e-commerce e um
-- segundo banco, de relatórios, com view e procedure próprias.
USE ecommerce;

-- Todo dia, cancela pedidos que ficaram mais de 3 dias aguardando pagamento.
-- (Só roda de fato com event_scheduler=ON; o backup leva a definição de qualquer forma.)
DROP EVENT IF EXISTS ev_cancelar_pedidos_parados;
CREATE EVENT ev_cancelar_pedidos_parados
  ON SCHEDULE EVERY 1 DAY STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR)
  DO
    UPDATE pedido SET status = 'cancelado'
    WHERE status = 'aguardando_pagamento' AND criado_em < NOW() - INTERVAL 3 DAY;

DROP DATABASE IF EXISTS relatorios;
CREATE DATABASE relatorios CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE relatorios;

CREATE TABLE fechamento_diario (
  dia          DATE PRIMARY KEY,
  pedidos      INT UNSIGNED NOT NULL,
  faturamento  DECIMAL(12, 2) NOT NULL,
  gerado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW vw_vendas_por_produto AS
SELECT pr.nome AS produto, SUM(i.quantidade) AS unidades, SUM(i.quantidade * i.preco_unitario) AS bruto
FROM ecommerce.item_pedido i
JOIN ecommerce.produto pr ON pr.id = i.produto_id
GROUP BY pr.id, pr.nome;

DELIMITER $$
CREATE PROCEDURE gerar_fechamento(IN p_dia DATE)
BEGIN
  REPLACE INTO fechamento_diario (dia, pedidos, faturamento)
  SELECT p_dia, COUNT(DISTINCT p.id), COALESCE(SUM(i.quantidade * i.preco_unitario) - SUM(DISTINCT p.desconto), 0)
  FROM ecommerce.pedido p
  JOIN ecommerce.item_pedido i ON i.pedido_id = p.id
  WHERE DATE(p.criado_em) = p_dia AND p.status <> 'cancelado';
END$$
DELIMITER ;

CALL gerar_fechamento(CURRENT_DATE);
