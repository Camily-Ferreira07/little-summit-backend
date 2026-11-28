-- =====================================================================
-- Little Summit - Massa de dados inicial para a apresentação (seed)
-- =====================================================================
-- COMO USAR:
--   1. Rode antes o database/little_summit.sql (cria as tabelas).
--   2. Suba o backend Spring Boot UMA vez (o DataInitializer cria os
--      usuários admin e operador com senha BCrypt).
--   3. Rode este arquivo no MySQL Workbench.
--
-- Este script pode ser executado várias vezes: ele apaga os dados de
-- negócio (insumos, produtos, receitas, ordens, movimentações e
-- histórico) e recria tudo do zero. A tabela users NÃO é alterada.
-- =====================================================================

USE little_summit;

-- Garante que o usuário admin existe (criado pelo DataInitializer).
-- Se o admin não existir, @admin_id fica NULL e os INSERTs de
-- stock_movements/history falham, avisando que falta subir o backend.
SET @admin_id = (SELECT id FROM users WHERE username = 'admin');

-- ---------------------------------------------------------------------
-- 1. Limpeza (ordem: das tabelas filhas para as tabelas pais)
-- ---------------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

DELETE FROM history;
DELETE FROM stock_movements;
DELETE FROM production_orders;
DELETE FROM product_materials;
DELETE FROM products;
DELETE FROM materials;

ALTER TABLE history           AUTO_INCREMENT = 1;
ALTER TABLE stock_movements   AUTO_INCREMENT = 1;
ALTER TABLE production_orders AUTO_INCREMENT = 1;
ALTER TABLE products          AUTO_INCREMENT = 1;
ALTER TABLE materials         AUTO_INCREMENT = 1;

SET SQL_SAFE_UPDATES = 1;

-- ---------------------------------------------------------------------
-- 2. Insumos (10)  -> ids 1 a 10, nesta ordem
-- ---------------------------------------------------------------------
-- Borracha Vedante já começa ABAIXO do mínimo (6 < 8) para o Dashboard
-- mostrar o alerta vermelho logo na abertura da demonstração.
INSERT INTO materials (name, unit, current_quantity, minimum_quantity) VALUES
('Chapa de Aço',       'un',  50.00, 10.00),   -- id 1
('Parafuso Sextavado', 'un', 200.00, 50.00),   -- id 2
('Tinta Industrial',   'L',   15.00,  5.00),   -- id 3
('Barra de Alumínio',  'm',   80.00, 20.00),   -- id 4
('Cabo de Cobre',      'm',  120.00, 30.00),   -- id 5
('Rolamento',          'un',  40.00, 10.00),   -- id 6
('Borracha Vedante',   'm',    6.00,  8.00),   -- id 7 (estoque crítico)
('Solvente',           'L',    6.00,  5.00),   -- id 8
('Porca Sextavada',    'un', 180.00, 40.00),   -- id 9
('Disjuntor',          'un',  30.00,  8.00);   -- id 10

-- ---------------------------------------------------------------------
-- 3. Produtos (4)  -> ids 1 a 4
-- ---------------------------------------------------------------------
INSERT INTO products (name, description) VALUES
('Suporte Metálico Padrão',   'Suporte estrutural montado e pintado'),            -- id 1
('Painel Elétrico Básico',    'Painel com cabeamento e chapa de proteção'),       -- id 2
('Eixo com Rolamento',        'Conjunto de eixo de alumínio com rolamentos'),     -- id 3
('Quadro de Distribuição',    'Quadro com disjuntores, cabeamento e chapa');      -- id 4

-- ---------------------------------------------------------------------
-- 4. Receitas (product_id, material_id, quantidade por unidade)
-- ---------------------------------------------------------------------
INSERT INTO product_materials (product_id, material_id, quantity_per_unit) VALUES
-- Suporte Metálico Padrão
(1, 1, 2.00),    -- 2 chapas de aço
(1, 2, 8.00),    -- 8 parafusos
(1, 3, 0.50),    -- 0,5 L de tinta
(1, 9, 8.00),    -- 8 porcas
-- Painel Elétrico Básico
(2, 1, 1.00),    -- 1 chapa de aço
(2, 2, 4.00),    -- 4 parafusos
(2, 5, 6.00),    -- 6 m de cabo
-- Eixo com Rolamento
(3, 4, 1.50),    -- 1,5 m de barra de alumínio
(3, 6, 2.00),    -- 2 rolamentos
(3, 7, 0.30),    -- 0,3 m de borracha
-- Quadro de Distribuição
(4, 1, 2.00),    -- 2 chapas de aço
(4, 10, 6.00),   -- 6 disjuntores
(4, 5, 10.00),   -- 10 m de cabo
(4, 9, 4.00);    -- 4 porcas

-- ---------------------------------------------------------------------
-- 5. Movimentações iniciais de estoque (todas de entrada)
-- ---------------------------------------------------------------------
-- A soma das entradas de cada insumo é IGUAL ao current_quantity dele
-- na tabela materials, então o saldo e o extrato ficam coerentes.
INSERT INTO stock_movements (material_id, user_id, type, quantity, notes, occurred_at) VALUES
(1,  @admin_id, 'IN',  30.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(1,  @admin_id, 'IN',  20.00, 'Compra - reposição de chapas',  '2026-11-09 10:30:00'),
(2,  @admin_id, 'IN', 200.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(3,  @admin_id, 'IN',  15.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(4,  @admin_id, 'IN',  50.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(4,  @admin_id, 'IN',  30.00, 'Compra - barras de alumínio',   '2026-11-10 14:00:00'),
(5,  @admin_id, 'IN', 120.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(6,  @admin_id, 'IN',  40.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(7,  @admin_id, 'IN',   6.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(8,  @admin_id, 'IN',   6.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(9,  @admin_id, 'IN', 180.00, 'Estoque inicial',               '2026-11-02 08:00:00'),
(10, @admin_id, 'IN',  30.00, 'Estoque inicial',               '2026-11-02 08:00:00');

-- ---------------------------------------------------------------------
-- 6. Registro no histórico de auditoria
-- ---------------------------------------------------------------------
INSERT INTO history (user_id, action, entity, entity_id, description) VALUES
(@admin_id, 'CREATE', 'MATERIAL', NULL, 'Carga inicial de dados de demonstração (seed.sql)');

-- ---------------------------------------------------------------------
-- 7. Conferência rápida (opcional): deve listar 10, 4, 14, 12 e 1
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM materials)         AS insumos,
  (SELECT COUNT(*) FROM products)          AS produtos,
  (SELECT COUNT(*) FROM product_materials) AS itens_de_receita,
  (SELECT COUNT(*) FROM stock_movements)   AS movimentacoes,
  (SELECT COUNT(*) FROM history)           AS historico;
