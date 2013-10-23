#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'mechanize'
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
