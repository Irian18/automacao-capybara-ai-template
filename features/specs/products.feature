# language: pt
@products
Funcionalidade: Exemplo de fluxo de listagem de produtos

    Cenário: Contagem de produtos no carrinho 
        Dado que acessei a página de login
        Quando adicionado os produtos:
            | Sauce Labs Backpack      |
            | Sauce Labs Bike Light    |
            | Sauce Labs Onesie        |
            | Sauce Labs Fleece Jacket |
        E removido o produto "Sauce Labs Onesie"
        Então no carrinho deve conter 3 produtos

    Esquema do Cenário: Preço de Produtos
        Dado que acessei a página de login
        Então o preço do produto "<produto>" deve ser "<preco>"

        Exemplos:
            | produto                             | preco  |
            | Sauce Labs Backpack                 | $29.99 |
            | Sauce Labs Bike Light               | $9.99  |
            | Sauce Labs Bolt T-Shirt             | $15.99 |
            | Sauce Labs Fleece Jacket            | $49.99 |
            | Sauce Labs Onesie                   | $7.99  |
            | Test.allTheThings() T-Shirt (Red)   | $15.99 |

    Cenário: Ordenação de produtos por nome do Maior para o Menor
        Dado que acessei a página de login
        Quando clicado em ordenação "Name (A to Z)"
        Então deve ser demonstrado primeiro os produtos:
            | Sauce Labs Backpack               |
            | Sauce Labs Bike Light             |
            | Sauce Labs Bolt T-Shirt           |
            | Sauce Labs Fleece Jacket          |
            | Sauce Labs Onesie                 |
            | Test.allTheThings() T-Shirt (Red) |

    Cenário: Ordenação de produtos por nome do Menor para o Maior
        Dado que acessei a página de login
        Quando clicado em ordenação "Name (Z to A)"
        Então deve ser demonstrado primeiro os produtos:
            | Test.allTheThings() T-Shirt (Red) |
            | Sauce Labs Onesie                 |
            | Sauce Labs Fleece Jacket          |
            | Sauce Labs Bolt T-Shirt           |
            | Sauce Labs Bike Light             |
            | Sauce Labs Backpack               |

    Cenário: Ordenação de produtos por preço do Menor para o Maior
        Dado que acessei a página de login
        Quando clicado em ordenação "Price (low to high)"
        Então deve ser demonstrado primeiro os produtos:
            | Sauce Labs Onesie                 |
            | Sauce Labs Bike Light             |
            | Sauce Labs Bolt T-Shirt           |
            | Test.allTheThings() T-Shirt (Red) |
            | Sauce Labs Backpack               |
            | Sauce Labs Fleece Jacket          |

    Cenário: Ordenação de produtos por preço do Maior para o Menor
        Dado que acessei a página de login
        Quando clicado em ordenação "Price (high to low)"
        Então deve ser demonstrado primeiro os produtos:
            | Sauce Labs Fleece Jacket          |
            | Sauce Labs Backpack               |
            | Sauce Labs Bolt T-Shirt           |
            | Test.allTheThings() T-Shirt (Red) |
            | Sauce Labs Bike Light             |
            | Sauce Labs Onesie                 |

    Cenário: Ordenação de produtos
        Dado que acessei a página de login
        Quando clicado em ordenação "Price (high to low)"
        Então deve ser demonstrado primeiro os produtos:
            | Sauce Labs Fleece Jacket          |
            | Sauce Labs Backpack               |
            | Sauce Labs Bolt T-Shirt           |
            | Test.allTheThings() T-Shirt (Red) |
            | Sauce Labs Bike Light             |
            | Sauce Labs Onesie                 |
