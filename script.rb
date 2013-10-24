#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'zip'

a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

# вводим в форму на странице логин и пароль, получаем куку
a.get('http://www.textilgroup.ru/xml.php') do |page|
  my_page = page.form_with(:action => '/xml.php?login=yes') do |f|
    f.USER_LOGIN      = 'partner'
    f.USER_PASSWORD   = '357975'
  end.click_button
end

# используя куку качаем файл
a.pluggable_parser.default = Mechanize::Download
a.get('http://www.textilgroup.ru/xml/postelinoe_belie.zip').save!('postelinoe_belie.zip')

# распаковываем архив
Zip::File.open('postelinoe_belie.zip') do |zipfile|
  zipfile.each do |file|
    file.extract('input.xml') { true }
  end
end

# парсим скаченный xml
doc = Nokogiri.XML(File.open('input.xml', 'rb'))

@xml = doc.xpath('//shop/products/product').map do |i|
  {
    'id' => i['id'],
    'cat' => i.at_xpath('category').content,
    'art' => i.at_xpath('articul').content,
    'price' => i.at_xpath('price').content,
    'desc' => i.at_xpath('description').content,
    'img_pw' => i.at_xpath('image_preview').content,
    'img_b' => i.at_xpath('image_big').content,
    'img_p' => i.at_xpath('image_pack').content,
    'size' => i.at_xpath('size').content,
    'mat' => i.at_xpath('material').content,
    'brend' => i.at_xpath('brend').content,
    'n_price' => i.at_xpath('name_price').content,
    'n_nak' => i.at_xpath('name_nak').content,
    'country' => i.at_xpath('country').content,
    'a' => i.at_xpath('avail').content
  }
end

# создаём YML
builder = Nokogiri::XML::Builder.new(:encoding => 'windows-1251') do |yml|
  yml.doc.create_internal_subset('yml_catalog', nil, 'http://partner.market.yandex.ru/pages/help/shops.dtd')
  yml.yml_catalog(:date => DateTime.now.new_offset(4.0/24).strftime('%Y-%m-%d %H:%M')) {
  yml.shop {
    yml.name 'Королевский сон'
    yml.company 'Индивидуальный Предприниматель Запорожец Диана Сергеевна,  ОГРН 310254009800012 от 8 апреля 2010г.'
    yml.url 'http://xn--b1afkebcevcagqrd.xn--p1ai/'
    yml.currencies {
      yml.currency(:id => 'RUR', :rate => '1')
    }
    yml.categories {
      yml.category(:id => '1') {
        yml.text('Постельное белье оптом')
      }
    }
    yml.offers {
      @xml.each do |o|
        yml.offer(:id => o['id'], :available => o['a'] == '1' ? 'true' : 'false') {
          yml.price o['price']
          yml.currencyId 'RUR'
          yml.categoryId '1'
          yml.picture o['img_pw']
          yml.picture o['img_b']
          yml.picture o['img_p']
          yml.name 'Комплект постельного белья'
          yml.description o['desc']
          yml.param(:name => 'Размер') {
            yml.text(o['size'])
          }
          yml.param(:name => 'Материал') {
            yml.text(o['mat'])
          }
          yml.param(:name => 'Артикул') {
            yml.text(o['art'])
          }
        }
      end
    }
  }
}
end

#пишем конечный результат в файл
File.open('output.xml', 'w') {
  |file| file.write(builder.to_xml)
}
