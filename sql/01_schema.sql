-- E-commerce enxuto para os exercícios de transação, backup e recovery.
DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ecommerce;

CREATE TABLE cliente (
  id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome   VARCHAR(120) NOT NULL,
  email  VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE produto (
  id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome     VARCHAR(120) NOT NULL,
  preco    DECIMAL(10, 2) NOT NULL,
  estoque  INT UNSIGNED NOT NULL,
  CONSTRAINT ck_produto_preco CHECK (preco > 0)
);

CREATE TABLE cupom (
  codigo      VARCHAR(20) PRIMARY KEY,
  percentual  TINYINT UNSIGNED NOT NULL,
  validade    DATE NOT NULL,
  usos_restantes INT UNSIGNED NOT NULL,
  CONSTRAINT ck_cupom_percentual CHECK (percentual BETWEEN 1 AND 90)
);

CREATE TABLE pedido (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id  INT UNSIGNED NOT NULL,
  status      ENUM('aguardando_pagamento', 'pago', 'cancelado') NOT NULL DEFAULT 'aguardando_pagamento',
  cupom       VARCHAR(20),
  desconto    DECIMAL(10, 2) NOT NULL DEFAULT 0,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES cliente (id),
  FOREIGN KEY (cupom) REFERENCES cupom (codigo)
);

CREATE TABLE item_pedido (
  pedido_id       INT UNSIGNED,
  produto_id      INT UNSIGNED,
  quantidade      INT UNSIGNED NOT NULL,
  preco_unitario  DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (pedido_id, produto_id),
  CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
  FOREIGN KEY (pedido_id) REFERENCES pedido (id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produto (id)
);

INSERT INTO cliente (id, nome, email) VALUES (1, 'Ana Souza', 'ana@email.com'), (2, 'Bruno Lima', 'bruno@email.com');
INSERT INTO produto (id, nome, preco, estoque) VALUES
  (1, 'Fone Bluetooth', 249.90, 10),
  (2, 'Teclado Mecânico', 389.00, 3),
  (3, 'Cabo USB-C 2 m', 39.90, 100);
INSERT INTO cupom VALUES ('BEMVINDO10', 10, '2099-12-31', 100), ('VENCIDO20', 20, '2020-01-01', 50), ('ESGOTADO15', 15, '2099-12-31', 0);
