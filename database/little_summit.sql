
CREATE DATABASE IF NOT EXISTS little_summit
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE little_summit;

-- 1. Usuários e perfis de acesso (ADM e USUARIO)
CREATE TABLE IF NOT EXISTS users (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    username   VARCHAR(50)  NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,              -- hash BCrypt
    role       ENUM('ADM', 'USUARIO') NOT NULL DEFAULT 'USUARIO',
    active     BOOLEAN  NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Materiais / insumos
CREATE TABLE IF NOT EXISTS materials (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(100) NOT NULL UNIQUE,
    unit             VARCHAR(20)  NOT NULL,        -- ex: un, kg, m, L
    current_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    minimum_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_mat_current CHECK (current_quantity >= 0),
    CONSTRAINT chk_mat_minimum CHECK (minimum_quantity >= 0)
);

-- 3. Produtos finais
CREATE TABLE IF NOT EXISTS products (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    active      BOOLEAN  NOT NULL DEFAULT TRUE,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Composição do produto (receita; N:N entre produto e material)
CREATE TABLE IF NOT EXISTS product_materials (
    product_id        BIGINT NOT NULL,
    material_id       BIGINT NOT NULL,
    quantity_per_unit DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (product_id, material_id),
    CONSTRAINT fk_pm_product  FOREIGN KEY (product_id)  REFERENCES products(id)  ON DELETE CASCADE,
    CONSTRAINT fk_pm_material FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE RESTRICT,
    CONSTRAINT chk_pm_qty CHECK (quantity_per_unit > 0)
);

-- 5. Ordens de produção
-- Fluxo direto: o sistema confere o estoque, dá baixa e grava a ordem como
-- COMPLETED na mesma transação. CANCELED fica para estorno (movimento IN).
CREATE TABLE IF NOT EXISTS production_orders (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id   BIGINT NOT NULL,
    user_id      BIGINT NOT NULL,
    quantity     INT NOT NULL,
    status       ENUM('COMPLETED', 'CANCELED') NOT NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_po_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_po_user    FOREIGN KEY (user_id)    REFERENCES users(id),
    CONSTRAINT chk_po_qty CHECK (quantity > 0)
);

-- 6. Movimentações de estoque
CREATE TABLE IF NOT EXISTS stock_movements (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    material_id         BIGINT NOT NULL,
    production_order_id BIGINT NULL,
    user_id             BIGINT NOT NULL,
    type                ENUM('IN', 'OUT', 'ADJUSTMENT') NOT NULL,
    quantity            DECIMAL(10, 2) NOT NULL,
    notes               VARCHAR(255),
    occurred_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sm_material FOREIGN KEY (material_id)         REFERENCES materials(id),
    CONSTRAINT fk_sm_order    FOREIGN KEY (production_order_id) REFERENCES production_orders(id),
    CONSTRAINT fk_sm_user     FOREIGN KEY (user_id)             REFERENCES users(id),
    CONSTRAINT chk_sm_qty CHECK (quantity > 0)
);

-- 7. Histórico de operações do sistema
CREATE TABLE IF NOT EXISTS history (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    action      VARCHAR(30)  NOT NULL,             -- CREATE, UPDATE, DELETE, PRODUCTION...
    entity      VARCHAR(30)  NOT NULL,             -- MATERIAL, PRODUCT, ORDER, USER
    entity_id   BIGINT NULL,
    description VARCHAR(255) NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hist_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Índices para as consultas mais comuns
CREATE INDEX idx_history_created  ON history (created_at);
CREATE INDEX idx_sm_material      ON stock_movements (material_id, occurred_at);
CREATE INDEX idx_po_product       ON production_orders (product_id);

-- =====================================================================
-- Dados de exemplo
-- =====================================================================

INSERT INTO materials (name, unit, current_quantity, minimum_quantity) VALUES
('Chapa de Aço',        'un', 50.00,  10.00),
('Parafuso Sextavado',  'un', 200.00, 50.00),
('Tinta Industrial',    'L',  15.00,  5.00),
('Barra de Alumínio',   'm',  80.00,  20.00),
('Cabo de Cobre',       'm',  120.00, 30.00),
('Rolamento',           'un', 40.00,  10.00),
('Borracha Vedante',    'm',  25.00,  8.00),
('Solvente',            'L',  6.00,   5.00);

INSERT INTO products (name, description) VALUES
('Suporte Metálico Padrão', 'Suporte estrutural montado e pintado'),
('Painel Elétrico Básico',  'Painel com cabeamento e chapa de proteção'),
('Eixo com Rolamento',      'Conjunto de eixo de alumínio com rolamentos');

INSERT INTO product_materials (product_id, material_id, quantity_per_unit) VALUES
-- Suporte Metálico Padrão
(1, 1, 2.00),   -- 2 chapas de aço
(1, 2, 8.00),   -- 8 parafusos
(1, 3, 0.50),   -- 0,5 L de tinta
-- Painel Elétrico Básico
(2, 1, 1.00),   -- 1 chapa de aço
(2, 2, 4.00),   -- 4 parafusos
(2, 5, 6.00),   -- 6 m de cabo
-- Eixo com Rolamento
(3, 4, 1.50),   -- 1,5 m de barra de alumínio
(3, 6, 2.00),   -- 2 rolamentos
(3, 7, 0.30);   -- 0,3 m de borracha

