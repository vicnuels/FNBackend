-- funçao para criptografar
CREATE OR REPLACE FUNCTION criptografar(campo TEXT, semente TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN MD5(semente || campo || semente);
END;
$$ LANGUAGE plpgsql;



-- operador
DROP TABLE IF EXISTS operador;
CREATE TABLE operador (
    codigo SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    login VARCHAR(255) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    CONSTRAINT unique_login UNIQUE (login)
);



-- criptografar operador
CREATE OR REPLACE FUNCTION criptografar_operador()
RETURNS TRIGGER AS $$
BEGIN
    NEW.login := criptografar(NEW.login, 'R6#GIRO2022@');
    NEW.senha := criptografar(NEW.senha, 'R6#GIRO2022@');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_operador
BEFORE INSERT ON operador
FOR EACH ROW
EXECUTE PROCEDURE criptografar_operador();

-- Função para criptografar operador durante atualização
CREATE OR REPLACE FUNCTION criptografar_operador_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.senha IS DISTINCT FROM OLD.senha THEN
        NEW.senha := criptografar(NEW.senha, 'R6#GIRO2022@');
    END IF;

    IF NEW.login IS DISTINCT FROM OLD.login THEN
        NEW.login := criptografar(NEW.login, 'R6#GIRO2022@');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger antes da atualização
CREATE TRIGGER before_update_operador
BEFORE UPDATE ON operador
FOR EACH ROW
EXECUTE PROCEDURE criptografar_operador_update();

-- validar login

CREATE OR REPLACE FUNCTION autenticar_usuario(login_input TEXT, senha_input TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    login_criptografado TEXT;
    senha_criptografada TEXT;
    usuario_existe BOOLEAN;
BEGIN
    -- Criptografa os valores de entrada
    login_criptografado := criptografar(login_input, 'R6#GIRO2022@');
    senha_criptografada := criptografar(senha_input, 'R6#GIRO2022@');

    -- Verifica se o usuário existe com o login e senha criptografados
    SELECT TRUE
    INTO usuario_existe
    FROM operador
    WHERE login = login_criptografado AND senha = senha_criptografada
    LIMIT 1;

    -- Retorna TRUE se o usuário existe, caso contrário FALSE
    RETURN COALESCE(usuario_existe, FALSE);
END;
$$ LANGUAGE plpgsql;

-- ADMIN
INSERT INTO operador (nome, login, senha) VALUES ('ADMIN', 'ADMIN', 'password');

-- tabela produto
DROP TABLE IF EXISTS produto;
CREATE TABLE produto
(
  codigo serial NOT NULL PRIMARY KEY,
  descricao character varying(255) NOT NULL,
  status boolean NOT NULL,
  estoque_negativo boolean NOT NULL,
  status_entrada boolean NOT NULL,
  status_saida boolean NOT NULL
);

-- LOCAL ESTOQUE

DROP TABLE IF EXISTS local_estoque;

CREATE TABLE local_estoque
(
  codigo serial NOT NULL PRIMARY KEY,
  descricao character varying(255) NOT NULL,
  status boolean NOT NULL
);

-- tabela entrada

DROP TABLE IF EXISTS entrada_mercadorias;

CREATE TABLE entrada_mercadorias
(
  codigo serial NOT NULL PRIMARY KEY,
  codigo_produto integer NOT NULL,
  codigo_local integer NOT NULL,
  lote character varying(50) NOT NULL,
  data_fabricacao date NOT NULL,
  data_vencimento date NOT NULL,
  quantidade numeric NOT NULL,
  data_hora timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT entrada_mercadorias_codigo_local_fkey FOREIGN KEY (codigo_local)
      REFERENCES local_estoque (codigo),
  CONSTRAINT entrada_mercadorias_codigo_produto_fkey FOREIGN KEY (codigo_produto)
      REFERENCES produto (codigo)
);


-- tabela saida 

DROP TABLE IF EXISTS saida_mercadorias;

CREATE TABLE saida_mercadorias
(
  codigo serial NOT NULL PRIMARY KEY,
  codigo_produto integer NOT NULL,
  codigo_local integer NOT NULL,
  lote character varying(50) NOT NULL,
  quantidade numeric NOT NULL,
  data_hora timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT saida_mercadorias_codigo_local_fkey FOREIGN KEY (codigo_local)
      REFERENCES local_estoque (codigo),
  CONSTRAINT saida_mercadorias_codigo_produto_fkey FOREIGN KEY (codigo_produto)
      REFERENCES produto (codigo)
);
