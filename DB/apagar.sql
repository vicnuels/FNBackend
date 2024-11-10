select ((select sum(quantidade) from entrada_mercadorias where codigo_produto = 1) - (select sum(quantidade) from saida_mercadorias where codigo_produto = 1)) as estoque, codigo, descricao, status, estoque_negativo, status_entrada, status_saida from produto where codigo = 1;



SELECT 
    p.*,
    COALESCE(em.total_entrada, 0) - COALESCE(sm.total_saida, 0) AS estoque
FROM 
    produto p
LEFT JOIN 
    (SELECT 
         codigo_produto, 
         SUM(quantidade) AS total_entrada 
     FROM 
         entrada_mercadorias 
     GROUP BY 
         codigo_produto) em 
ON 
    p.codigo = em.codigo_produto
LEFT JOIN 
    (SELECT 
         codigo_produto, 
         SUM(quantidade) AS total_saida 
     FROM 
         saida_mercadorias 
     GROUP BY 
         codigo_produto) sm 
ON 
    p.codigo = sm.codigo_produto;
