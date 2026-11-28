# Configuração do MySQL em Rede Local — Little Summit

Projeto Integrador (3º semestre).

**Responsável:** Sara Alves
**Função no projeto:** banco de dados em rede (Máquina 1) e testes de integração

Este documento descreve como o servidor MySQL da **Máquina 1** foi configurado para atender o backend Spring Boot (Máquina 2) pela rede local. **Senhas e endereços IP não constam aqui** e são passados ao grupo por mensagem privada.

## Visão geral da topologia

| Máquina | Função | Porta |
|---|---|---|
| Máquina 1 | Servidor MySQL 8.0 (schema `little_summit`) | 3306 |
| Máquina 2 | Backend Spring Boot (`little-summit-backend`) | 8080 |
| Máquina 3 | Cliente desktop JavaFX | — |

## 1. Instalação (Máquina 1)

1. Instalar o **MySQL Installer – Community** (MySQL Server 8.0.x, arquitetura x64) a partir de https://dev.mysql.com/downloads/installer/.
2. No assistente, manter a porta padrão **3306** e definir a senha do usuário `root` (guardada fora do repositório).
3. Pelo MySQL Installer, adicionar o **MySQL Workbench 8.0**, usado para executar os scripts e consultar o banco.

## 2. Criação do banco e das tabelas

1. No Workbench, conectar em `Local instance MySQL80` com o usuário `root`.
2. Abrir e executar `database/little_summit.sql` (File → Open SQL Script, depois executar com o raio).
3. Conferir se o schema `little_summit` tem as 7 tabelas: `users`, `materials`, `products`, `product_materials`, `production_orders`, `stock_movements` e `history`.

## 3. Usuário dedicado para acesso pela rede

O `root` não é usado pelo backend na rede. Foi criado um usuário próprio, com acesso apenas ao schema do projeto:

```sql
CREATE USER 'littlesummit'@'%' IDENTIFIED BY '<senha>';
GRANT ALL PRIVILEGES ON little_summit.* TO 'littlesummit'@'%';
FLUSH PRIVILEGES;
```

O host `'%'` permite que a Máquina 2 se conecte por IP, sem a restrição de `localhost`.

## 4. Liberação da porta 3306 no firewall (Máquina 1)

Regra de entrada TCP para a porta 3306, criada com o PowerShell em modo administrador:

```
New-NetFirewallRule -DisplayName "MySQL Little Summit" -Direction Inbound -Protocol TCP -LocalPort 3306 -Action Allow
```

## 5. Conexão a partir do backend (Máquina 2)

Na Máquina 2, a URL do banco aponta para o IP da Máquina 1, sem alterar o `application.properties` do repositório (configuração por variáveis de ambiente):

```
SPRING_DATASOURCE_URL=jdbc:mysql://<IP_MAQUINA_1>:3306/little_summit?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo
SPRING_DATASOURCE_USERNAME=littlesummit
SPRING_DATASOURCE_PASSWORD=<senha>
```

Na primeira execução, o backend cria os usuários `admin` e `operador` (`DataInitializer`). Depois disso, executar `database/seed.sql` para carregar os dados de demonstração.

## 6. Verificações

Marque apenas o que foi realmente feito e conferido.

| Verificação | Feito |
|---|---|
| MySQL instalado e Workbench conectando em `localhost` | [x] |
| `little_summit.sql` executado e 7 tabelas criadas | [x] |
| Usuário `littlesummit` criado com acesso ao schema | [x] |
| Regra de firewall da porta 3306 criada | [x] |
| `netstat -an \| findstr 3306` mostra `0.0.0.0:3306` em `LISTENING` | [x] |
| Conexão no Workbench com o usuário `littlesummit` pelo IP da própria máquina | [ ] |
| Conexão de **outra máquina da rede** com o usuário `littlesummit` | [ ] |
| Backend na Máquina 2 conectado ao banco da Máquina 1 | [ ] |

## 7. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Communications link failure` / timeout | Firewall bloqueando a 3306, IP errado ou máquinas em redes diferentes | Conferir a regra do firewall, o IP (`ipconfig`) e se as máquinas estão na mesma rede |
| `Access denied for user 'littlesummit'` | Senha errada ou usuário não criado | Conferir a senha; recriar o usuário conforme a seção 3 |
| `netstat` mostra só `127.0.0.1:3306` | MySQL escutando apenas localmente | Ajustar o `bind-address` no `my.ini` e reiniciar o serviço do MySQL |
| IP mudou | Troca de rede ou reinício do roteador | Rodar `ipconfig` de novo e atualizar a URL na Máquina 2 |

## 8. Segurança

- A senha do `root` e a do usuário `littlesummit` **não** são versionadas no GitHub.
- O backend lê a senha por variável de ambiente (`DB_PASSWORD` ou `SPRING_DATASOURCE_PASSWORD`).
- O usuário `littlesummit` tem permissões apenas sobre o schema `little_summit`.
