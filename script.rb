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
    file.extract('output.xml')
  end
end

# парсим скаченный xml
doc = Nokogiri.XML(File.open('output.xml', 'rb'))

@xml = doc.xpath('//shop/products/product').map do |i|
  {
    'cat' => i.at_xpath('category').content,
    'art' => i.at_xpath('articul').content,
    'price' => i.at_xpath('price').content,
    'desc' => i.at_xpath('description').content,
    'img' => i.at_xpath('image_big').content,
    'size' => i.at_xpath('size').content,
    'mat' => i.at_xpath('material').content,
    'brend' => i.at_xpath('brend').content,
    'n_price' => i.at_xpath('name_price').content,
    'n_nak' => i.at_xpath('name_nak').content,
    'country' => i.at_xpath('country').content,
    'a' => i.at_xpath('avail').content
  }
end
