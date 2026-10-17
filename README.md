hs2json
# hs2json

Biblioteca em Haskell para representar valores JSON, formatá-los com um pretty printer próprio e testar tudo com propriedades usando QuickCheck.

Projeto da Avaliação da Unidade 2 da disciplina de Haskell (UFMA), desenvolvido em dupla a partir do tutorial *Construindo e Testando uma Biblioteca Haskell: JSON, Pretty Printing e QuickCheck*.

## Vídeo de apresentação

**Link: <COLE AQUI O LINK DO YOUTUBE OU DO GOOGLE DRIVE>**

## Integrantes

- Arthur Sampaio Pereira (<https://github.com/arthurswntg2000>)
- André Moura Lima (<https://github.com/AndreMouraL>)

## Visão geral

O projeto tem três partes:

1. Um tipo algébrico `JValue` com funções de extração que não lançam exceção.
2. Uma biblioteca de pretty printing baseada no tipo `Doc`, que respeita largura máxima e indentação.
3. Um renderizador que transforma `JValue` em `Doc`, com escape correto de strings, e uma suíte de testes com QuickCheck.

## Requisitos

- GHC 9.x (desenvolvido e testado com 9.10.3)
- Cabal 3.0 ou superior
- QuickCheck 2.14 ou superior, que o próprio Cabal baixa na primeira execução

## Como executar

Na raiz do repositório:

```
cabal build
cabal run hs2json-exe
cabal test
```

`cabal build` compila a biblioteca, o executável e a suíte de testes. `cabal run hs2json-exe` roda uma demonstração que imprime um objeto JSON em formato compacto e em formato pretty, com larguras 20 e 80. `cabal test` executa todas as propriedades.

Para ver a saída completa dos testes no terminal, e não só o caminho do log:

```
cabal test --test-show-details=direct
```

Para medir a cobertura com o HPC:

```
cabal test --enable-coverage
```

Ao final, o Cabal informa o caminho do arquivo `hpc_index.html`, que mostra a cobertura por módulo e o código-fonte colorido.

Para testar propriedades isoladamente no GHCi:

```
cabal repl test:hs2json-test
ghci> quickCheck prop_empty_id
ghci> sample (arbitrary :: Gen Doc)
```

### Observação para Windows com OneDrive

Com o repositório dentro de uma pasta sincronizada pelo OneDrive, o Cabal pode falhar com `permission denied (Acesso negado)` ao recriar o diretório `dist-newstyle`. Usamos um diretório de build fora do OneDrive:

```
cabal test --builddir=C:\build\hs2json
cabal run hs2json-exe --builddir=C:\build\hs2json
```

## Estrutura do repositório

```
hs2json/
├── hs2json.cabal
├── app/
│   └── Main.hs
├── src/
│   ├── SimpleJSON.hs
│   ├── Prettify.hs
│   ├── PrettyJSON.hs
│   └── QuickTestes.hs
└── test/
    └── Spec.hs
```

| Arquivo | Conteúdo |
| --- | --- |
| `src/SimpleJSON.hs` | tipo `JValue` e funções de extração |
| `src/Prettify.hs` | tipo `Doc` e combinadores de pretty printing |
| `src/PrettyJSON.hs` | conversão de `JValue` para `Doc` |
| `src/QuickTestes.hs` | propriedades de exemplo sobre uma ordenação (`qsort`) |
| `app/Main.hs` | programa de demonstração |
| `test/Spec.hs` | suíte de testes executada por `cabal test` |

Os quatro módulos de `src/` estão em `exposed-modules` da biblioteca. O executável e a suíte de testes dependem dela.

## Arquitetura

### SimpleJSON

```haskell
data JValue = JNull
            | JBool Bool
            | JNumber Double
            | JString String
            | JArray [JValue]
            | JObject [(String, JValue)]
```

As funções `getString`, `getInt`, `getDouble`, `getBool`, `getObject` e `getArray` devolvem `Maybe`: `Just` quando o valor tem o construtor esperado e `Nothing` nos demais casos. `isNull` devolve `Bool`. `getInt` trunca o número, já que o JSON não distingue inteiros de números de ponto flutuante.

### Prettify

O tipo `Doc` descreve um documento em construção:

```haskell
data Doc = Empty
         | Char Char
         | Text String
         | Line
         | Concat Doc Doc
         | Union Doc Doc
         | Nest Int Doc
```

| Função | Papel |
| --- | --- |
| `empty`, `char`, `text`, `double`, `line` | constroem documentos simples |
| `(<>)` | concatena dois documentos; `empty` é a identidade |
| `concatDoc`, `enclose`, `punctuate`, `fsep` | combinam listas de documentos |
| `softline`, `group` | marcam quebras de linha opcionais |
| `nest` | aumenta a indentação das quebras de linha |
| `fill` | completa com espaços até uma largura |
| `compact` | renderiza sem indentação e sem considerar largura |
| `pretty w` | renderiza respeitando largura máxima `w` e a indentação |

O `Union` guarda duas alternativas de layout, uma achatada e outra com quebras. O `pretty` escolhe a primeira quando ela cabe na largura disponível.

O módulo exporta `Doc(..)`, com os construtores, porque os testes precisam construir e inspecionar documentos. Numa biblioteca de produção o usual seria separar um módulo interno com os construtores e expor só a interface abstrata.

### PrettyJSON

`renderJValue :: JValue -> Doc` converte um valor JSON em documento. Arrays e objetos passam por uma função auxiliar que combina `enclose`, `nest 2`, `fsep` e `punctuate`: quando cabem na largura ficam numa linha, e quando não cabem quebram com indentação de dois espaços.

Strings são escapadas caractere a caractere. Os escapes simples (`\b`, `\n`, `\f`, `\r`, `\t`, `\\`, `\"`) usam a forma curta. Caracteres de controle, o DEL e tudo acima de `\xff` viram `\uXXXX`, e os caracteres fora do plano básico do Unicode são escritos como par substituto.

### Exemplo

Para o valor

```haskell
JObject [("nome", JString "Arthur e Andre"), ("disciplina", JString "Haskell"), ("notas", JArray [JNumber 10.0, JNumber 9.5])]
```

`pretty 20` produz:

```
{"nome": "Arthur e Andre",
  "disciplina": "Haskell",
  "notas": [10.0,
    9.5]}
```

e `pretty 80` produz:

```
{"nome": "Arthur e Andre", "disciplina": "Haskell", "notas": [10.0, 9.5]}
```

## Testes

A suíte fica em `test/Spec.hs`. As funções cujo nome começa com `prop_` são descobertas por `quickCheckAll`, que usa Template Haskell, e executadas em conjunto. Se alguma propriedade falhar, o programa termina com `exitFailure` e o `cabal test` reporta a falha. As propriedades de ordenação, que vêm de outro módulo, rodam em seguida com `quickCheckResult`.

### Geradores

- `Arbitrary Doc` escolhe entre os sete construtores com `oneof`. Os textos gerados incluem caracteres Unicode e de controle, que são os que mais costumam revelar erros de escape.
- `Arbitrary JValue` usa `sized` para limitar a profundidade da árvore e `resize (n `div` 2)` em volta de cada `listOf` para limitar a largura. Os números gerados são sempre finitos, para que `v == v` valha para qualquer valor gerado.

### Propriedades

| Propriedade | O que verifica |
| --- | --- |
| `prop_empty_id` | `empty` é identidade de `(<>)` dos dois lados |
| `prop_char`, `prop_text`, `prop_line`, `prop_double` | os construtores básicos produzem a estrutura esperada |
| `prop_concatDoc` | `concatDoc` coincide com um modelo escrito sobre listas |
| `prop_punctuate'` | `punctuate` coincide com `intersperse` seguido da eliminação dos `Empty` |
| `prop_fillLargura`, `prop_fillNaoCorta` | `fill` completa até a largura pedida e não corta texto maior |
| `prop_nestIndenta`, `prop_nestZero` | `nest` indenta as linhas seguintes, e `nest 0` não altera o resultado |
| `prop_stringsComAspas` | strings JSON saem entre aspas |
| `prop_compact_text` | `compact (text s) == s` |
| `prop_pretty_text` | `pretty w (text s) == s` para qualquer largura |
| `prop_getString`, `prop_getBool`, `prop_getDouble`, `prop_getInt` | cada função de extração devolve o conteúdo do seu construtor |
| `prop_accessorsCoerentes` | com o construtor errado, as funções de extração devolvem `Nothing` |
| `prop_isNull` | `isNull v` equivale a `v == JNull` |
| `prop_escapesSeguros` | a saída de uma string não contém caractere de controle, DEL nem caractere acima de `\xff` |
| `prop_escapesConhecidos` | casos conhecidos: `\n`, `\t`, aspas, barra invertida, `é`, `\u04d2` e um emoji |
| `prop_layoutEquivalente` | `pretty` (qualquer largura) e `compact` só diferem em espaços e quebras de linha |

São 23 propriedades em `Spec.hs`, mais as 7 de ordenação de `QuickTestes` (idempotência, saída ordenada, permutação, mínimo, máximo, mínimo da concatenação e comparação com `Data.List.sort`). A propriedade `prop_minimum` falha de propósito, porque usa `head` em lista vazia, e por isso fica fora da suíte.

## Dificuldades encontradas

**Tipo abstrato e testabilidade.** Na primeira versão o `Doc` era exportado sem os construtores, e o gerador `Arbitrary Doc` não compilava, já que precisa montar documentos diretamente. Passamos a exportar `Doc(..)`. A alternativa mais limpa seria um módulo interno, mas para o escopo do trabalho a exportação direta bastou.

**Modelo de `punctuate`.** O primeiro modelo, `punctuate s xs == intersperse s xs`, parecia correto e foi falsificado pelo QuickCheck em poucos testes. O contraexemplo tinha um `Empty` dentro de um `Concat`: o operador `(<>)` descarta `Empty`, e `intersperse` não. Corrigimos o modelo para também eliminar os `Empty`, e a propriedade passou a valer.

**Falha sem código de saída.** Uma suíte que apenas imprime que falhou é reportada como PASS pelo Cabal, porque ele só olha o código de saída. Por isso o `main` termina com `exitFailure` quando alguma propriedade não passa.

**Geradores recursivos com listas.** Em `JValue`, a recursão passa por listas (`JArray` e `JObject`). Reduzir um contador de profundidade não limita o comprimento das listas, porque `listOf` usa o tamanho ambiente do QuickCheck, que cresce até 100. A árvore fica limitada em profundidade, mas não em largura, e o consumo de memória explode. Resolvemos com `resize (n `div` 2)` em volta de cada `listOf`.

**Template Haskell no `quickCheckAll`.** O `quickCheckAll` só enxerga as definições anteriores à linha `return []`, e só as do próprio módulo. Por isso o `return []` vem depois de todas as propriedades, e as de `QuickTestes` continuam numa lista com `quickCheckResult`.

**OneDrive.** O Cabal falhava com `Acesso negado` ao recriar o diretório de build dentro da pasta sincronizada. Resolvemos com `--builddir` apontando para fora do OneDrive.

## Referências

- Tutorial da disciplina: *Construindo e Testando uma Biblioteca Haskell: JSON, Pretty Printing e QuickCheck*.
- Baseado nos capítulos 5 e 11 de *Real World Haskell*, de Bryan O'Sullivan, Don Stewart e John Goerzen, sob licença Creative Commons Attribution-Noncommercial 3.0. Tradução do projeto rwh-ptbr.
- Documentação do QuickCheck: https://hackage.haskell.org/package/QuickCheck