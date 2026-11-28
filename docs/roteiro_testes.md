# Roteiro de Testes de Integração — Little Summit

Projeto Integrador (3º semestre).

**Responsável pelos testes:** Sara Alves
**Data da execução:** 28/11/2026

## Escopo desta execução

Os testes foram feitos **no computador da Máquina 1**, com o backend Spring Boot e o MySQL rodando na mesma máquina (`localhost`). A API foi chamada com `curl`. O cliente JavaFX e a topologia de 3 máquinas em rede ainda **não foram testados**.

## Resumo

| Cenário | Descrição | Situação |
|---|---|---|
| 1 | Login USUARIO e bloqueio de `/api/users` | **Parcial**: API validada; menu da tela JavaFX pendente |
| 2 | ADM cadastra usuário e senha criptografada | **FALHOU**: senha salva em texto puro |
| 3 | Simulação acima do estoque bloqueia a produção | Pendente na API; regra validada no banco (ver `validacoes_banco.md`) |
| 4 | Produção válida abate estoque e registra | Pendente na API; abatimento validado no banco (ver `validacoes_banco.md`) |
| 5 | Alerta de estoque crítico no Dashboard | Pendente (API e tela); consulta validada no banco (ver `validacoes_banco.md`) |

---

## Cenário 1 — Login como USUARIO e bloqueio de usuários

**O que foi feito:** com o backend ligado, chamada a `GET /api/users` com autenticação HTTP Basic, primeiro como `operador` e depois como `admin`.

```
curl.exe -i -u operador:operador123 http://localhost:8080/api/users
curl.exe -i -u admin:admin123 http://localhost:8080/api/users
```

**Esperado:** `operador` recebe HTTP 403; `admin` recebe HTTP 200 com a lista de usuários.

**Resultado obtido:**
- `operador`: **HTTP/1.1 403** (`"error":"Forbidden"`, `"path":"/api/users"`).
- `admin`: **HTTP/1.1 200**, com a lista dos usuários `admin` (ADM) e `operador` (USUARIO).

- **Status (API):** OK
- **Pendente:** confirmar na tela JavaFX que o botão "Usuários" fica oculto para o perfil USUARIO.
- **Prints:** `docs/evidencias/cenario1_operador_403.png` e `docs/evidencias/cenario1_admin_200.png`

---

## Cenário 2 — ADM cadastra usuário e senha criptografada com BCrypt

**O que foi feito:** cadastro do usuário `teste01` (perfil USUARIO, senha `senha123`) por `POST /api/users`, autenticado como `admin`. Em seguida, consulta no MySQL:

```sql
SELECT id, username, password, role FROM little_summit.users;
```

**Esperado:** o usuário novo aparece na tabela e a coluna `password` mostra um hash BCrypt (texto longo começando com `$2a$`), nunca a senha em texto puro.

**Resultado obtido:**
- O usuário `teste01` foi criado (id 4).
- A coluna `password` do `teste01` contém **`senha123`, em texto puro**.
- Os usuários `admin` e `operador`, criados pelo `DataInitializer`, têm hash `$2a$10$...` corretamente.

- **Status:** **FALHOU**
- **Causa provável:** o cadastro pela API (`UserService`) salva a senha sem passar pelo `PasswordEncoder` (BCrypt) antes de gravar.
- **Impacto:** senhas expostas no banco e usuários cadastrados pela API provavelmente não conseguem fazer login, já que o Spring Security espera o hash.
- **Encaminhamento:** reportado ao responsável pelo módulo de usuários. Reteste com um usuário novo após a correção.
- **Print:** `docs/evidencias/cenario2_bcrypt_FALHA.png`

---

## Cenário 3 — Simulação acima do estoque bloqueia a produção

**Situação: PENDENTE na API.** Depende do módulo de produção (`/api/production`), ainda não disponível na versão testada.

**Validação feita diretamente no banco (sem a API):**
- Simulação de viabilidade para 100 Suportes Metálicos Padrão: os 4 insumos ficam inviáveis, com as faltas calculadas.
- Tentativa de baixar mais estoque do que existe: o MySQL recusa com erro 3819 (`chk_mat_current`) e o saldo permanece intacto.

Detalhes e prints em `docs/validacoes_banco.md`.

---

## Cenário 4 — Produção válida abate estoque e registra movimentações

**Situação: PENDENTE na API.** Depende do módulo de produção e de movimentações.

**Validação feita diretamente no banco (sem a API):** o abatimento dos insumos de 5 Suportes Metálicos Padrão produz os saldos esperados (Chapa 40, Parafuso 160, Tinta 12,5, Porca 140) e é desfeito com `ROLLBACK`. A gravação em `stock_movements` e `history` ainda não foi testada.

Detalhes e prints em `docs/validacoes_banco.md`.

---

## Cenário 5 — Insumo abaixo do mínimo gera alerta no Dashboard

**Situação: PENDENTE** (API de insumos e tela do Dashboard).

**Validação feita diretamente no banco (sem a API):** após o abatimento dos insumos de 16 Painéis Elétricos Básicos, a consulta de estoque crítico lista Cabo de Cobre (24, mínimo 30) e Borracha Vedante (6, mínimo 8). O alerta visual no Dashboard não foi testado.

Detalhes e prints em `docs/validacoes_banco.md`.

---

## Pendências gerais

- Reteste do cenário 2 depois da correção do `UserService`.
- Cenários 3, 4 e 5 pela API e pelas telas JavaFX.
- Menu de Usuários oculto na tela para o perfil USUARIO (cenário 1).
- Teste com as 3 máquinas em rede local (MySQL na Máquina 1, backend na Máquina 2, cliente JavaFX na Máquina 3).
