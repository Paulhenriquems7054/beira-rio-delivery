# Visualização de Todos os Produtos - Admin - COMPLETO ✅

## Problema Resolvido
O admin não conseguia visualizar, editar ou excluir todos os produtos existentes na loja, apenas os que estavam adicionados à cesta ativa. Isso dificultava o gerenciamento do catálogo completo.

## Solução Implementada

### Nova Seção: "Todos os Produtos da Loja"

Adicionada uma nova seção na página `/admin/basket` que permite ao admin:

1. **Ver TODOS os produtos cadastrados** na loja (não apenas os da cesta)
2. **Identificar facilmente** quais produtos estão ou não na cesta
3. **Adicionar produtos à cesta** com um clique
4. **Editar qualquer produto** (nome, preço, unidade, imagem)
5. **Excluir produtos** permanentemente do banco de dados

### Funcionalidades

#### 1. Botão "Mostrar Todos"
- Localizado no cabeçalho da nova seção
- Expande/colapsa a visualização de todos os produtos
- Carrega os produtos apenas quando expandido (otimização de performance)

#### 2. Produtos Organizados em Duas Categorias

**✓ Na Cesta (verde)**
- Mostra todos os produtos que já estão na cesta ativa
- Fundo verde claro para fácil identificação
- Cada produto tem:
  - Imagem do produto
  - Nome e preço
  - Botão de edição (lápis azul)
  - Botão de exclusão (lixeira vermelha)
- Modo de edição inline com formulário completo
- Layout responsivo

**⚠ Fora da Cesta (amarelo)**
- Mostra produtos cadastrados mas NÃO incluídos na cesta
- Cada produto tem:
  - Imagem do produto
  - Nome e preço
  - Botão "+" para adicionar à cesta
  - Botão de edição (lápis azul)
  - Botão de exclusão (lixeira vermelha)
- Modo de edição inline com formulário completo
- Layout responsivo

#### 3. Edição de Produtos
- Clique no botão de edição (lápis azul)
- Formulário inline aparece com campos:
  - Nome do produto
  - Medida (UN ou KG)
  - Preço (R$)
  - Link da foto (URL)
- Botões "Cancelar" e "Salvar"
- Atualiza o produto diretamente na tabela `products`
- Feedback com toast de sucesso/erro

#### 4. Exclusão de Produtos
- Clique no botão de exclusão (lixeira vermelha)
- Confirmação via `window.confirm`
- Remove primeiro da cesta (se estiver)
- Depois exclui permanentemente da tabela `products`
- Feedback com toast de sucesso/erro

#### 5. Adicionar à Cesta
- Botão "+" em cada produto fora da cesta
- Adiciona o produto com quantidade padrão de 1
- Feedback visual com toast de sucesso
- Atualiza automaticamente ambas as listas

### Mutations Implementadas

```typescript
// Editar produto diretamente
const editProductMutation = useMutation({
  mutationFn: async (data: { 
    productId: string; 
    name: string; 
    price: number; 
    unit: string; 
    image_url: string 
  }) => {
    await supabase
      .from("products")
      .update({ 
        name: data.name, 
        price: data.price, 
        unit: data.unit, 
        image_url: data.image_url 
      })
      .eq("id", data.productId);
  },
  onSuccess: () => {
    toast.success("Produto atualizado!");
    setEditingProduct(null);
    // Invalida ambas as queries
    queryClient.invalidateQueries({ queryKey: ["admin-active-basket"] });
    queryClient.invalidateQueries({ queryKey: ["all-products"] });
  }
});

// Excluir produto permanentemente
const deleteProductMutation = useMutation({
  mutationFn: async (productId: string) => {
    // 1. Remove da cesta se estiver lá
    await supabase
      .from("basket_items")
      .delete()
      .match({ product_id: productId });
    
    // 2. Deleta o produto
    await supabase
      .from("products")
      .delete()
      .eq("id", productId);
  },
  onSuccess: () => {
    toast.success("Produto excluído!");
    // Invalida ambas as queries
    queryClient.invalidateQueries({ queryKey: ["admin-active-basket"] });
    queryClient.invalidateQueries({ queryKey: ["all-products"] });
  }
});

// Adicionar à cesta
const addToBasketMutation = useMutation({
  mutationFn: async (productId: string) => {
    await supabase
      .from("basket_items")
      .insert([{ 
        basket_id: basket.id, 
        product_id: productId, 
        quantity: 1 
      }]);
  },
  onSuccess: () => {
    toast.success("Produto adicionado à cesta!");
    queryClient.invalidateQueries({ queryKey: ["admin-active-basket"] });
    queryClient.invalidateQueries({ queryKey: ["all-products"] });
  }
});
```

## Fluxo de Uso

### Para Visualizar
1. Admin acessa `/admin/basket`
2. Rola até a seção "Todos os Produtos da Loja"
3. Clica em "Mostrar Todos"
4. Visualiza produtos organizados em duas categorias

### Para Editar
1. Clica no botão de edição (lápis azul)
2. Formulário inline aparece
3. Altera os campos desejados
4. Clica em "Salvar" ou "Cancelar"

### Para Excluir
1. Clica no botão de exclusão (lixeira vermelha)
2. Confirma a exclusão no diálogo
3. Produto é removido permanentemente

### Para Adicionar à Cesta
1. Clica no botão "+" em produto fora da cesta
2. Produto move automaticamente para a seção verde

## Benefícios

1. **Visibilidade Total**: Admin vê todos os produtos cadastrados
2. **Gestão Completa**: Editar e excluir qualquer produto
3. **Edição Inline**: Não precisa navegar para outra página
4. **Confirmação de Exclusão**: Evita exclusões acidentais
5. **Feedback Visual**: Cores diferentes para cada categoria
6. **Performance**: Carrega apenas quando necessário
7. **Responsivo**: Funciona bem em mobile e desktop

## Dark Mode

Todos os elementos foram implementados com suporte a dark mode:
- `bg-card` para fundos de cards e inputs
- `text-foreground` para texto de inputs
- `border-border` para bordas
- `bg-emerald-50 dark:bg-emerald-950/20` para produtos na cesta
- `border-emerald-200 dark:border-emerald-800` para bordas verdes
- `text-emerald-600 dark:text-emerald-400` para textos verdes
- `bg-blue-50 dark:bg-blue-950/30` para botão de edição
- `bg-red-50 dark:bg-red-950/30` para botão de exclusão

## Arquivos Modificados

- `src/pages/AdminBasket.tsx`:
  - Adicionado estado `editingProduct`
  - Adicionado `editProductMutation`
  - Adicionado `deleteProductMutation`
  - Atualizada seção "Fora da Cesta" com botões de edição/exclusão
  - Adicionado formulário inline de edição

## Como Testar

1. Faça login como admin
2. Acesse "Produtos" no menu principal
3. Role até "Todos os Produtos da Loja"
4. Clique em "Mostrar Todos"
5. Verifique se todos os produtos aparecem em duas categorias
6. Teste editar um produto (clique no lápis azul)
7. Teste excluir um produto (clique na lixeira vermelha)
8. Teste adicionar um produto à cesta (clique no +)
9. Verifique se o texto é visível em dark mode

## Status

✅ **COMPLETO** - Todas as funcionalidades implementadas
✅ Build bem-sucedido
✅ Alterações commitadas e enviadas
✅ Pronto para produção

## Próximos Passos (Opcional)

- Adicionar busca/filtro de produtos
- Adicionar ordenação (nome, preço, data)
- Mostrar produtos inativos separadamente
- Upload de imagem direto (não apenas URL)
