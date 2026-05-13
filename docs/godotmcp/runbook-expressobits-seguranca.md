# Runbook: Segurança GDExtension e ExpressoBits Inventory System

## O Risco Critico
O projeto **Rogue Agent** utiliza o addon `ExpressoBits Inventory System` que roda via **GDExtension (C++)**. Diferente de scripts GDScript nativos, objetos instanciados do C++ (como `Inventory` e `ItemStack`) sao extremamente rigidos. Tentar forcar tipagem dinamica do GDScript neles causa *Null References* silenciosos e quebra a telemetria do jogo inteiro.

## Regra de Ouro: Tratamento do `ItemStack`
A classe `ItemStack` gerada pela base de dados do ExpressoBits possui uma estrutura fixa no back-end C++. 

**ERRADO (Causa crash do combate):**
```gdscript
# Nunca tente injetar o recurso do item dentro da stack.
# A propriedade "item" nao existe na versao compilada e sera apagada.
stack.set("item", item_definition_resource) 
var molde = stack.get("item") # RETORNARA NULL
```

**CORRETO (Aprovado no V14):**
Sempre referencie o ID como String e use o Banco de Dados para extrair a Definicao.
```gdscript
# Como extrair a definicao com seguranca:
var item_id = str(stack.get("item_id"))
var definition = inventory.database.get_item(item_id)
```

## Regra de Prata: Dicionario `properties`
Para fazer loots aleatorios (Dynamic Loot) no estilo Diablo/PoE, o unico local seguro dentro do `ItemStack` para salvar atributos customizados e rolados (como dano da arma, durabilidade, modificadores magicos) e dentro do Dicionario nativo `properties`.
```gdscript
# Certo:
stack.properties["rolled_damage"] = 15
stack.properties["rolled_dex_bonus"] = 2
```

## Injeção Autoritatíva (A API de Inventory)
NUNCA modifique a array de stacks manualmente para adicionar itens em gameplays ou scripts de QA. Fazer um `.append(stack)` corrompe o signal loop interno do C++ (`contents_changed`).
Sempre utilize os metodos de autoridade `NexusInventoryAuthority.apply_add_item(...)` ou a API nativa do inventario: `inventory.add(item_id, amount, properties_dictionary)`.