-- Criação da tabela autores
CREATE TABLE autores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    data_nascimento DATE,
    nacionalidade VARCHAR(100),
    biografia TEXT,
    data_falecimento DATE,
    pais_origem VARCHAR(100),
    obras_notaveis TEXT[],
    twitter VARCHAR(50) UNIQUE,
    facebook VARCHAR(50) UNIQUE,
    
    -- Restrições adicionais
    CHECK (data_nascimento <= CURRENT_DATE),
    CHECK (data_falecimento IS NULL OR data_falecimento <= CURRENT_DATE),
    CHECK (cardinality(obras_notaveis) > 0),
    CHECK (twitter IS NULL OR twitter ~ '^@'),
    CHECK (facebook IS NULL OR position('facebook.com' in facebook) > 0)
);
SELECT * FROM autores;

-- Criação da tabela livros
CREATE TABLE livros (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    autor_id INT REFERENCES autores(id) NOT NULL,
    ano_publicacao INT,
    editora VARCHAR(255),
    genero VARCHAR(100),
    num_paginas INT,
    quantidade_disponivel INT NOT NULL,
    resumo TEXT,
    imagem_capa VARCHAR(255),
    
    -- Restrições adicionais
    CHECK (ano_publicacao >= 0),
    CHECK (num_paginas >= 0),
    CHECK (quantidade_disponivel >= 0),
    UNIQUE (titulo, autor_id)
);
SELECT * FROM livros;

-- Criação da tabela usuarios
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    endereco TEXT,
    email VARCHAR(255) UNIQUE,
    telefone VARCHAR(20) UNIQUE,
    data_nascimento DATE,
    genero VARCHAR(20),
    status_membro VARCHAR(20),
    historico_emprestimos_usuario JSONB[],
    tipo_membro VARCHAR(50) NOT NULL
);
SELECT * FROM usuarios;

-- Criação da tabela emprestimos
CREATE TABLE emprestimos (
    id SERIAL PRIMARY KEY,
    data_emprestimo DATE NOT NULL,
    data_devolucao_prevista DATE NOT NULL,
    livro_id INT REFERENCES livros(id) NOT NULL,
    usuario_id INT REFERENCES usuarios(id) NOT NULL,
    data_devolucao_real DATE,
    status_emprestimo VARCHAR(20) NOT NULL,
    valor_multa DECIMAL(10, 2),
    comentarios TEXT,
    historico_emprestimos_usuario JSONB[],
    tipo_emprestimo VARCHAR(20) NOT NULL,
    renovacoes INT DEFAULT 0 NOT NULL,
    
    -- Restrições adicionais
    CHECK (valor_multa >= 0),
    CHECK (renovacoes >= 0),
    UNIQUE (livro_id, usuario_id, data_emprestimo)
);

-- Trigger associado à função para verificar historico_emprestimos
CREATE OR REPLACE FUNCTION check_historico_emprestimos()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        cardinality(NEW.historico_emprestimos_usuario) > 0 AND 
        NOT EXISTS (
            SELECT 1 
            FROM unnest(NEW.historico_emprestimos_usuario) AS t(e)
            WHERE jsonb_typeof(t.e) = 'object'
        )
    ) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Todos os elementos de historico_emprestimos_usuario devem ser do tipo jsonb';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado à tabela emprestimos
CREATE TRIGGER trigger_check_historico_emprestimos
BEFORE INSERT OR UPDATE
ON emprestimos
FOR EACH ROW
EXECUTE FUNCTION check_historico_emprestimos();

-- Inserções na tabela autores
INSERT INTO autores (nome, data_nascimento, nacionalidade, biografia, twitter, facebook)
VALUES
  ('Autor 1', '1980-01-01', 'Nacionalidade 1', 'Biografia do Autor 1', '@autor1', 'facebook.com/autor1'),
  ('Autor 2', '1975-02-15', 'Nacionalidade 2', 'Biografia do Autor 2', '@autor2', 'facebook.com/autor2'),
  ('Autor 3', '1982-03-20', 'Nacionalidade 3', 'Biografia do Autor 3', '@autor3', 'facebook.com/autor3'),
  ('Autor 4', '1990-04-25', 'Nacionalidade 4', 'Biografia do Autor 4', '@autor4', 'facebook.com/autor4'),
  ('Autor 5', '1985-06-30', 'Nacionalidade 5', 'Biografia do Autor 5', '@autor5', 'facebook.com/autor5');
select * from autores;
-- Inserções na tabela livros
INSERT INTO livros (titulo, autor_id, ano_publicacao, editora, genero, num_paginas, quantidade_disponivel, resumo)
VALUES
  ('Livro 1', 11, 2000, 'Editora 1', 'Gênero 1', 300, 10, 'Resumo do Livro 1'),
  ('Livro 2', 12, 2010, 'Editora 2', 'Gênero 2', 250, 15, 'Resumo do Livro 2'),
  ('Livro 3', 13, 2005, 'Editora 3', 'Gênero 3', 400, 8, 'Resumo do Livro 3'),
  ('Livro 4', 14, 2015, 'Editora 4', 'Gênero 4', 350, 12, 'Resumo do Livro 4'),
  ('Livro 5', 15, 2020, 'Editora 5', 'Gênero 5', 280, 20, 'Resumo do Livro 5');

select * from livros;
-- Inserções na tabela usuarios
INSERT INTO usuarios (nome, endereco, email, telefone, data_nascimento, genero, status_membro, historico_emprestimos_usuario, tipo_membro)
VALUES
  ('Usuário 1', 'Endereço 1', 'usuario1@email.com', '127-456-7890', '1992-01-10', 'Masculino', 'Ativo', ARRAY['{"livro": "Livro 1", "data_emprestimo": "2022-01-15"}'::jsonb], 'Premium'),
  ('Usuário 2', 'Endereço 2', 'usuario2@email.com', '987-654-3210', '1988-02-20', 'Feminino', 'Ativo', ARRAY['{"livro": "Livro 2", "data_emprestimo": "2022-02-25"}'::jsonb], 'Padrão'),
  ('Usuário 3', 'Endereço 3', 'usuario3@email.com', '575-123-4567', '1995-03-30', 'Masculino', 'Inativo', ARRAY['{"livro": "Livro 3", "data_emprestimo": "2022-03-05"}'::jsonb], 'Premium'),
  ('Usuário 4', 'Endereço 4', 'usuario4@email.com', '1171-222-3333', '1980-04-10', 'Feminino', 'Ativo', ARRAY['{"livro": "Livro 4", "data_emprestimo": "2022-04-15"}'::jsonb], 'Padrão'),
  ('Usuário 5', 'Endereço 5', 'usuario5@email.com', '7777-888-9999', '1993-05-20', 'Masculino', 'Inativo', ARRAY['{"livro": "Livro 5", "data_emprestimo": "2022-05-25"}'::jsonb], 'Premium');






DROP TRIGGER IF EXISTS trigger_check_historico_emprestimos ON emprestimos;
-- Trigger associado à tabela emprestimos
CREATE OR REPLACE FUNCTION check_historico_emprestimos()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        TG_OP = 'INSERT' AND
        cardinality(NEW.historico_emprestimos_usuario) > 0 AND 
        NOT EXISTS (
            SELECT 1 
            FROM unnest(NEW.historico_emprestimos_usuario) AS t(e)
            WHERE jsonb_typeof(t.e) = 'object'
        )
    ) THEN
        RAISE EXCEPTION 'Todos os elementos de historico_emprestimos_usuario devem ser do tipo jsonb';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criação da trigger atualizada
CREATE TRIGGER trigger_check_historico_emprestimos
BEFORE INSERT OR UPDATE
ON emprestimos
FOR EACH ROW
EXECUTE FUNCTION check_historico_emprestimos();
-- Inserções na tabela emprestimos
INSERT INTO emprestimos (data_emprestimo, data_devolucao_prevista, livro_id, usuario_id, status_emprestimo, tipo_emprestimo)
VALUES
  ('2022-01-15', '2022-02-15', 16, 6, 'Em andamento', 'Comum'),
  ('2022-02-25', '2022-03-25', 17, 7, 'Concluído', 'Comum'),
  ('2022-03-05', '2022-04-05', 18, 8, 'Em atraso', 'Comum'),
  ('2022-04-15', '2022-05-15', 19, 9, 'Em andamento', 'Comum'),
  ('2022-05-25', '2022-06-25', 20, 10, 'Concluído', 'Comum');
  
  
 --iniciando os join
  select * from usuarios;
  
  SELECT
    livros.id AS livro_id,
    livros.titulo AS livro_titulo,
    autores.id AS autor_id,
    autores.nome AS autor_nome
FROM
    livros
JOIN
    autores ON livros.autor_id = autores.id;
-- join 2
SELECT
    emprestimos.id AS emprestimo_id,
    livros.titulo AS livro_titulo,
    autores.nome AS autor_nome,
    usuarios.nome AS usuario_nome,
    emprestimos.data_emprestimo,
    emprestimos.data_devolucao_prevista,
    emprestimos.status_emprestimo
FROM
    emprestimos
JOIN
    livros ON emprestimos.livro_id = livros.id
JOIN
    autores ON livros.autor_id = autores.id
JOIN
    usuarios ON emprestimos.usuario_id = usuarios.id;