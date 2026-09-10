-- ============================================================
--  PostureCare — Sistema Inteligente de Monitoramento Ergonômico
--  Banco de Dados MySQL
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- ============================================================
-- 1. CRIAÇÃO DO SCHEMA
-- ============================================================
CREATE DATABASE IF NOT EXISTS posturecare
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE posturecare;

-- ============================================================
-- 2. TABELAS (ordem respeita dependências de FK)
-- ============================================================

-- 2.1 PERFIL_SAUDE — perfil físico/saúde do usuário
CREATE TABLE IF NOT EXISTS PERFIL_SAUDE (
    id_perfil         INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    altura_m          DECIMAL(4,2)    NOT NULL COMMENT 'Altura em metros (ex: 1.75)',
    idade             TINYINT UNSIGNED NOT NULL COMMENT 'Idade em anos',
    imc_calculado     DECIMAL(5,2)    GENERATED ALWAYS AS (NULL) VIRTUAL
                          COMMENT 'Calculado via trigger/app; deixado como NULL aqui',
    nivel_atividade   ENUM('sedentario','leve','moderado','intenso','muito_intenso')
                          NOT NULL DEFAULT 'moderado',
    objetivo_texto    VARCHAR(500)    NULL COMMENT 'Objetivo livre do usuário',
    criado_em         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                          ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_perfil)
) ENGINE=InnoDB
  COMMENT='Perfil de saúde e atividade física do usuário';


-- 2.2 USUARIO — entidade central
CREATE TABLE IF NOT EXISTS USUARIO (
    id_usuario        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    nome              VARCHAR(150)    NOT NULL,
    email             VARCHAR(254)    NOT NULL,
    senha_hash        CHAR(60)        NOT NULL COMMENT 'bcrypt hash',
    aceitou_termos    TINYINT(1)      NOT NULL DEFAULT 0,
    data_aceite_termos DATETIME       NULL,
    data_cadastro     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultimo_acesso     DATETIME        NULL,
    id_perfil         INT UNSIGNED    NULL COMMENT 'FK → PERFIL_SAUDE',
    PRIMARY KEY (id_usuario),
    UNIQUE KEY uq_usuario_email (email),
    CONSTRAINT fk_usuario_perfil
        FOREIGN KEY (id_perfil) REFERENCES PERFIL_SAUDE (id_perfil)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Usuários do sistema';


-- 2.3 CONFIGURACAO_PREFERENCIAS — preferências de notificação
CREATE TABLE IF NOT EXISTS CONFIGURACAO_PREFERENCIAS (
    id_config              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    id_usuario             INT UNSIGNED  NOT NULL,
    ativar_notificacoes    TINYINT(1)    NOT NULL DEFAULT 1,
    frequencia_alertas     ENUM('baixa','media','alta') NOT NULL DEFAULT 'media',
    lembrete_bem_estar     TIME          NULL COMMENT 'Horário diário do lembrete',
    lembrete_hidratacao    TIME          NULL,
    compartilhar_dados_anonimos TINYINT(1) NOT NULL DEFAULT 0,
    criado_em              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                               ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_config),
    UNIQUE KEY uq_config_usuario (id_usuario),
    CONSTRAINT fk_config_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Preferências de alertas e notificações por usuário';


-- 2.4 SESSAO_POSTURA — sessões de monitoramento postural
CREATE TABLE IF NOT EXISTS SESSAO_POSTURA (
    data_hora_inicio      DATETIME     NOT NULL,
    id_usuario            INT UNSIGNED NOT NULL,
    data_hora_fim         DATETIME     NULL,
    pontuacao_postura     DECIMAL(5,2) NULL COMMENT 'Score 0-100',
    status_predominante   ENUM('correta','alerta','critica') NULL,
    sincronizado_offline  TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (data_hora_inicio, id_usuario),
    CONSTRAINT fk_sessao_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Sessões de monitoramento de postura (pode ser registrada offline)';


-- 2.5 REGISTRO_ALERTA — alertas gerados durante sessões
CREATE TABLE IF NOT EXISTS REGISTRO_ALERTA (
    id_alerta         INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    id_usuario        INT UNSIGNED    NOT NULL,
    sessao_inicio     DATETIME        NULL COMMENT 'FK → SESSAO_POSTURA',
    data_hora         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo_desvio       ENUM('cabeca_frente','ombro_elevado','coluna_curvada',
                           'posicao_tela','outro') NOT NULL,
    duracao_segundos  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (id_alerta),
    INDEX idx_alerta_usuario (id_usuario),
    INDEX idx_alerta_data    (data_hora),
    CONSTRAINT fk_alerta_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_alerta_sessao
        FOREIGN KEY (sessao_inicio, id_usuario)
        REFERENCES SESSAO_POSTURA (data_hora_inicio, id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Registro individual de cada alerta postural disparado';


-- 2.6 EXERCICIO — catálogo de exercícios disponíveis
CREATE TABLE IF NOT EXISTS EXERCICIO (
    id_exercicio      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    titulo            VARCHAR(150)    NOT NULL,
    descricao         TEXT            NULL,
    categoria         ENUM('alongamento','fortalecimento','mobilidade',
                           'respiracao','pausa_ativa') NOT NULL,
    dificuldade       ENUM('iniciante','intermediario','avancado') NOT NULL DEFAULT 'iniciante',
    duracao_minutos   TINYINT UNSIGNED NOT NULL DEFAULT 5,
    PRIMARY KEY (id_exercicio),
    INDEX idx_exercicio_categoria (categoria)
) ENGINE=InnoDB
  COMMENT='Catálogo de exercícios ergonômicos';


-- 2.7 EXERCICIO_REALIZADO — histórico de exercícios feitos pelo usuário
CREATE TABLE IF NOT EXISTS EXERCICIO_REALIZADO (
    id_realizacao       INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    id_usuario          INT UNSIGNED    NOT NULL,
    id_exercicio        INT UNSIGNED    NOT NULL,
    data_hora           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duracao_efetiva_min TINYINT UNSIGNED NULL,
    concluido           TINYINT(1)      NOT NULL DEFAULT 1,
    PRIMARY KEY (id_realizacao),
    INDEX idx_realizado_usuario  (id_usuario),
    INDEX idx_realizado_data     (data_hora),
    CONSTRAINT fk_realizado_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_realizado_exercicio
        FOREIGN KEY (id_exercicio) REFERENCES EXERCICIO (id_exercicio)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Exercícios realizados por cada usuário';


-- 2.8 SCORE_HISTORICO_7D — snapshots diários dos últimos 7 dias
CREATE TABLE IF NOT EXISTS SCORE_HISTORICO_7D (
    id                INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    id_usuario        INT UNSIGNED    NOT NULL,
    dia_semana        DATE            NOT NULL,
    score_valor       DECIMAL(5,2)    NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_score_usuario_dia (id_usuario, dia_semana),
    CONSTRAINT fk_score_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Score diário de postura — janela deslizante de 7 dias';


-- 2.9 METRICA_DIARIA — consolidado diário de métricas
CREATE TABLE IF NOT EXISTS METRICA_DIARIA (
    id_metrica          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    id_usuario          INT UNSIGNED    NOT NULL,
    data_registro       DATE            NOT NULL,
    score_hoje          DECIMAL(5,2)    NULL,
    tempo_sentado_hs    DECIMAL(4,2)    NULL COMMENT 'Horas sentado no dia',
    qtd_alertas         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    qtd_exercicios      TINYINT UNSIGNED  NOT NULL DEFAULT 0,
    dias_sequencia      SMALLINT UNSIGNED NOT NULL DEFAULT 0
                            COMMENT 'Streak de dias consecutivos ativos',
    id_score_historico  INT UNSIGNED    NULL COMMENT 'FK → SCORE_HISTORICO_7D',
    PRIMARY KEY (id_metrica),
    UNIQUE KEY uq_metrica_usuario_data (id_usuario, data_registro),
    CONSTRAINT fk_metrica_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_metrica_score
        FOREIGN KEY (id_score_historico) REFERENCES SCORE_HISTORICO_7D (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Consolidado diário de métricas de postura e atividade';


-- 2.10 PROGRESSO_GERAL_PERFIL — progresso acumulado do usuário
CREATE TABLE IF NOT EXISTS PROGRESSO_GERAL_PERFIL (
    id_progresso              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    id_usuario                INT UNSIGNED    NOT NULL,
    score_medio_7d            DECIMAL(5,2)    NULL,
    exercicios_concluidos_total INT UNSIGNED  NOT NULL DEFAULT 0,
    meta_exercicios_total     INT UNSIGNED    NOT NULL DEFAULT 30,
    dias_consecutivos_atual   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    meta_dias_consecutivos    SMALLINT UNSIGNED NOT NULL DEFAULT 7,
    atualizado_em             DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_progresso),
    UNIQUE KEY uq_progresso_usuario (id_usuario),
    CONSTRAINT fk_progresso_usuario
        FOREIGN KEY (id_usuario) REFERENCES USUARIO (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Visão consolidada de progresso e metas por usuário';


-- ============================================================
-- 3. ÍNDICES ADICIONAIS
-- ============================================================
CREATE INDEX idx_sessao_usuario_data
    ON SESSAO_POSTURA (id_usuario, data_hora_inicio);

CREATE INDEX idx_metrica_data
    ON METRICA_DIARIA (data_registro);

CREATE INDEX idx_score_historico_dia
    ON SCORE_HISTORICO_7D (dia_semana);

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- 4. TRIGGER — IMC calculado ao inserir/atualizar PERFIL_SAUDE
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_perfil_imc_insert
BEFORE INSERT ON PERFIL_SAUDE
FOR EACH ROW
BEGIN
    -- IMC = peso / altura² — peso não está no diagrama, ajuste conforme modelo final
    -- Placeholder: atualiza a coluna gerada via app; trigger aqui serve de exemplo
    SET NEW.atualizado_em = NOW();
END$$

CREATE TRIGGER trg_usuario_aceitou_termos
BEFORE UPDATE ON USUARIO
FOR EACH ROW
BEGIN
    IF NEW.aceitou_termos = 1 AND OLD.aceitou_termos = 0 THEN
        SET NEW.data_aceite_termos = NOW();
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- 5. VIEW — Resumo diário por usuário (útil para dashboard)
-- ============================================================
CREATE OR REPLACE VIEW vw_resumo_diario AS
SELECT
    u.id_usuario,
    u.nome,
    md.data_registro,
    md.score_hoje,
    md.tempo_sentado_hs,
    md.qtd_alertas,
    md.qtd_exercicios,
    md.dias_sequencia,
    pg.score_medio_7d,
    pg.exercicios_concluidos_total,
    pg.dias_consecutivos_atual
FROM USUARIO u
LEFT JOIN METRICA_DIARIA md
    ON u.id_usuario = md.id_usuario
    AND md.data_registro = CURDATE()
LEFT JOIN PROGRESSO_GERAL_PERFIL pg
    ON u.id_usuario = pg.id_usuario;


-- ============================================================
-- 6. DADOS DE EXEMPLO
-- ============================================================

-- 6.1 Perfis de Saúde
INSERT INTO PERFIL_SAUDE (altura_m, idade, nivel_atividade, objetivo_texto) VALUES
(1.75, 32, 'moderado',   'Melhorar postura no home office e reduzir dores nas costas'),
(1.62, 28, 'leve',       'Aliviar tensão nos ombros após longas horas no computador'),
(1.80, 45, 'intenso',    'Manter mobilidade e prevenir lesões por esforço repetitivo'),
(1.68, 37, 'sedentario', 'Adquirir hábito de pausas ativas durante o expediente'),
(1.55, 24, 'moderado',   'Correção postural para treinos de academia');

-- 6.2 Usuários
INSERT INTO USUARIO (nome, email, senha_hash, aceitou_termos, data_aceite_termos,
                     data_cadastro, ultimo_acesso, id_perfil) VALUES
('Ana Souza',      'ana.souza@email.com',   '$2b$12$KIX8X9pHqR1cL2mN3oP4Qu', 1, '2026-01-15 10:00:00', '2026-01-15 09:58:00', '2026-09-03 08:30:00', 1),
('Bruno Lima',     'bruno.lima@email.com',  '$2b$12$LJY9Y0qIS2dM3nO4pQ5Rv', 1, '2026-02-03 14:22:00', '2026-02-03 14:20:00', '2026-09-02 18:45:00', 2),
('Carlos Mendes',  'carlos.m@email.com',    '$2b$12$MKZ0Z1rJT3eN4oP5qR6Sw', 1, '2026-03-10 09:00:00', '2026-03-10 08:55:00', '2026-09-03 07:10:00', 3),
('Diana Ferreira', 'diana.f@email.com',     '$2b$12$NLA1A2sKU4fO5pQ6rS7Tx', 1, '2026-04-20 16:05:00', '2026-04-20 16:00:00', '2026-08-30 12:00:00', 4),
('Eduardo Rocha',  'eduardo.r@email.com',   '$2b$12$OMB2B3tLV5gP6qR7sT8Uy', 1, '2026-05-08 11:30:00', '2026-05-08 11:28:00', '2026-09-01 09:00:00', 5);

-- 6.3 Configurações de Preferências
INSERT INTO CONFIGURACAO_PREFERENCIAS
    (id_usuario, ativar_notificacoes, frequencia_alertas,
     lembrete_bem_estar, lembrete_hidratacao, compartilhar_dados_anonimos) VALUES
(1, 1, 'alta',   '10:00:00', '09:30:00', 1),
(2, 1, 'media',  '11:00:00', '10:00:00', 0),
(3, 1, 'media',  '09:00:00', '08:30:00', 1),
(4, 0, 'baixa',  NULL,        NULL,       0),
(5, 1, 'alta',   '12:00:00', '11:00:00', 1);

-- 6.4 Sessões de Postura
INSERT INTO SESSAO_POSTURA
    (data_hora_inicio, id_usuario, data_hora_fim, pontuacao_postura,
     status_predominante, sincronizado_offline) VALUES
('2026-09-03 08:00:00', 1, '2026-09-03 09:30:00', 82.5, 'correta',  0),
('2026-09-03 08:15:00', 2, '2026-09-03 10:00:00', 65.0, 'alerta',   0),
('2026-09-02 09:00:00', 3, '2026-09-02 11:00:00', 91.0, 'correta',  0),
('2026-09-02 10:30:00', 4, '2026-09-02 12:30:00', 48.3, 'critica',  1),
('2026-09-03 07:45:00', 5, '2026-09-03 09:15:00', 77.8, 'alerta',   0);

-- 6.5 Registros de Alerta
INSERT INTO REGISTRO_ALERTA
    (id_usuario, sessao_inicio, data_hora, tipo_desvio, duracao_segundos) VALUES
(1, '2026-09-03 08:00:00', '2026-09-03 08:20:00', 'cabeca_frente',  45),
(1, '2026-09-03 08:00:00', '2026-09-03 08:55:00', 'ombro_elevado',  30),
(2, '2026-09-03 08:15:00', '2026-09-03 08:45:00', 'coluna_curvada', 120),
(2, '2026-09-03 08:15:00', '2026-09-03 09:30:00', 'posicao_tela',   60),
(3, '2026-09-02 09:00:00', '2026-09-02 09:40:00', 'ombro_elevado',  20),
(4, '2026-09-02 10:30:00', '2026-09-02 10:50:00', 'coluna_curvada', 300),
(4, '2026-09-02 10:30:00', '2026-09-02 11:30:00', 'cabeca_frente',  180),
(5, '2026-09-03 07:45:00', '2026-09-03 08:30:00', 'outro',           90);

-- 6.6 Catálogo de Exercícios
INSERT INTO EXERCICIO (titulo, descricao, categoria, dificuldade, duracao_minutos) VALUES
('Rotação de pescoço',        'Gire o pescoço lentamente em semicírculo para aliviar tensão cervical.',           'alongamento',      'iniciante',     3),
('Alongamento de ombros',     'Cruze o braço à frente do peito e pressione com o outro braço por 20 segundos.', 'alongamento',      'iniciante',     5),
('Fortalecimento de core',    'Prancha frontal com foco em respiração diafragmática.',                           'fortalecimento',   'intermediario', 10),
('Mobilidade torácica',       'Rotação do tronco sentado na cadeira, 10 repetições por lado.',                   'mobilidade',       'iniciante',     5),
('Respiração abdominal',      'Inspire pelo nariz expandindo o abdômen; expire lentamente pela boca.',           'respiracao',       'iniciante',     5),
('Pausa ativa de 5 minutos',  'Levante-se, caminhe e faça movimentos leves para ativar a circulação.',          'pausa_ativa',      'iniciante',     5),
('Flexão de joelhos em pé',   'Agachamento parcial usando a mesa como apoio. Fortalece MMII e ativa glúteos.',  'fortalecimento',   'intermediario', 8),
('Retração escapular',        'Empurre as escápulas em direção à coluna por 5 segundos. 10 repetições.',        'fortalecimento',   'iniciante',     4);

-- 6.7 Exercícios Realizados
INSERT INTO EXERCICIO_REALIZADO
    (id_usuario, id_exercicio, data_hora, duracao_efetiva_min, concluido) VALUES
(1, 1, '2026-09-03 08:35:00', 3,  1),
(1, 6, '2026-09-03 09:35:00', 5,  1),
(2, 2, '2026-09-03 09:00:00', 5,  1),
(3, 3, '2026-09-02 10:00:00', 10, 1),
(3, 4, '2026-09-02 10:15:00', 5,  1),
(4, 5, '2026-09-02 11:00:00', 4,  0),
(5, 8, '2026-09-03 08:00:00', 4,  1),
(5, 6, '2026-09-03 09:20:00', 5,  1),
(1, 4, '2026-09-02 14:00:00', 5,  1),
(2, 7, '2026-09-01 16:00:00', 8,  1);

-- 6.8 Score Histórico 7 Dias
INSERT INTO SCORE_HISTORICO_7D (id_usuario, dia_semana, score_valor) VALUES
(1, '2026-08-28', 78.0), (1, '2026-08-29', 80.5), (1, '2026-08-30', 76.0),
(1, '2026-09-01', 83.0), (1, '2026-09-02', 85.0), (1, '2026-09-03', 82.5),
(2, '2026-08-28', 60.0), (2, '2026-08-29', 62.0), (2, '2026-09-01', 64.0),
(2, '2026-09-02', 63.5), (2, '2026-09-03', 65.0),
(3, '2026-09-01', 88.0), (3, '2026-09-02', 91.0),
(4, '2026-09-02', 48.3),
(5, '2026-09-01', 74.0), (5, '2026-09-02', 76.5), (5, '2026-09-03', 77.8);

-- 6.9 Métricas Diárias
INSERT INTO METRICA_DIARIA
    (id_usuario, data_registro, score_hoje, tempo_sentado_hs,
     qtd_alertas, qtd_exercicios, dias_sequencia, id_score_historico) VALUES
(1, '2026-09-03', 82.5, 1.5,  2, 2, 15, 6),
(1, '2026-09-02', 85.0, 2.0,  1, 1, 14, 5),
(2, '2026-09-03', 65.0, 1.75, 2, 1,  3, 11),
(3, '2026-09-02', 91.0, 2.0,  1, 2, 22, 12),
(4, '2026-09-02', 48.3, 2.0,  2, 0,  1, 14),
(5, '2026-09-03', 77.8, 1.5,  1, 2,  8, 17);

-- 6.10 Progresso Geral
INSERT INTO PROGRESSO_GERAL_PERFIL
    (id_usuario, score_medio_7d, exercicios_concluidos_total,
     meta_exercicios_total, dias_consecutivos_atual, meta_dias_consecutivos) VALUES
(1, 80.8, 42, 50, 15,  21),
(2, 63.7, 18, 30,  3,  10),
(3, 89.5, 67, 70, 22,  30),
(4, 48.3,  5, 20,  1,   7),
(5, 76.1, 25, 40,  8,  14);


-- ============================================================
-- 7. CONSULTAS ÚTEIS (comentadas — execute conforme necessário)
-- ============================================================

/*
-- Ranking de usuários pelo score médio dos últimos 7 dias
SELECT u.nome, pg.score_medio_7d, pg.dias_consecutivos_atual
FROM PROGRESSO_GERAL_PERFIL pg
JOIN USUARIO u ON pg.id_usuario = u.id_usuario
ORDER BY pg.score_medio_7d DESC;

-- Alertas por tipo, contagem geral
SELECT tipo_desvio, COUNT(*) AS total, AVG(duracao_segundos) AS media_seg
FROM REGISTRO_ALERTA
GROUP BY tipo_desvio
ORDER BY total DESC;

-- Exercícios mais realizados
SELECT e.titulo, COUNT(*) AS vezes_feito
FROM EXERCICIO_REALIZADO er
JOIN EXERCICIO e ON er.id_exercicio = e.id_exercicio
WHERE er.concluido = 1
GROUP BY e.id_exercicio, e.titulo
ORDER BY vezes_feito DESC;

-- Score histórico de um usuário nos últimos 7 dias
SELECT dia_semana, score_valor
FROM SCORE_HISTORICO_7D
WHERE id_usuario = 1
ORDER BY dia_semana;

-- Resumo diário hoje (via view)
SELECT * FROM vw_resumo_diario
WHERE data_registro = CURDATE();
*/
