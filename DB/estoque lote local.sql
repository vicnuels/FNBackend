SELECT 
    p.codigo AS codigo_produto,
    p.descricao AS descricao_produto,
    p.estoque_negativo,
    em.lote,
    em.data_fabricacao,
    em.data_vencimento,
    em.codigo_local,
    le.descricao AS descricao_local,
    COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque
FROM 
    produto p
LEFT JOIN (
    SELECT 
        codigo_produto, 
        lote,
        codigo_local,
        data_fabricacao,
        data_vencimento,
        SUM(quantidade) AS total_entrada 
    FROM 
        entrada_mercadorias 
    GROUP BY 
        codigo_produto, lote, codigo_local, data_fabricacao, data_vencimento
) em 
ON 
    p.codigo = em.codigo_produto
LEFT JOIN (
    SELECT 
        codigo_produto, 
        lote,
        codigo_local,
        SUM(quantidade) AS total_saida 
    FROM 
        saida_mercadorias 
    GROUP BY 
        codigo_produto, lote, codigo_local
) sm 
ON 
    p.codigo = sm.codigo_produto 
    AND em.lote = sm.lote 
    AND em.codigo_local = sm.codigo_local
LEFT JOIN 
    local_estoque le 
ON 
    em.codigo_local = le.codigo
WHERE 
    COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) <> 0 
    OR (p.estoque_negativo = true and em.lote <> '')
ORDER BY em.data_vencimento asc;
