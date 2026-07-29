def garantir_login
  login.load
  login.logar_usuario('standard_user', 'secret_sauce')
end

Quando('adicionado os produtos:') do |tabela|
  garantir_login
  tabela.raw.flatten.each do |produto|
    item = products.find_item_by_name(produto)
    item.add_to_cart
  end
end

Quando('removido o produto {string}') do |produto|
  item = products.find_item_by_name(produto)
  item.btn_remove.click
end

Então('no carrinho deve conter {int} produtos') do |quantidade|
  expect(products.badge_shopping_cart).to have_text(quantidade.to_s)
end

Então('o preço do produto {string} deve ser {string}') do |produto, preco|
  garantir_login
  item = products.find_item_by_name(produto)
  raise "Produto '#{produto}' não encontrado na listagem" if item.nil?

  expect(item.label_price).to have_text(preco)
end

Quando('clicado em ordenação {string}') do |ordenacao|
  garantir_login
  products.sort_by(ordenacao)
end

Então('deve ser demonstrado primeiro os produtos:') do |tabela|
  produtos_esperados = tabela.raw.flatten
  produtos_na_tela = products.inventory_items.map { |item| item.label_title.text.strip }
  expect(produtos_na_tela).to eq(produtos_esperados)
end
