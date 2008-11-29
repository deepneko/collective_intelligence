#!/usr/bin/env ruby
require 'cgi'
require 'searcher.rb'
require 'const.rb'

$const = Const.new
$searcher = Searcher.new($const.dbname, $const.nn)

def search(keyword)
  $searcher.query(keyword)
end

$head = <<"HEAD"
<html><head>
<title>Search Engine - Collective Intelligence Chapter 4</title>
<style>
BODY, TD, TR{font-size:12px}
A{text-decoration:none}
</style>
</head>
<body bgcolor=#ffffff link=#00004c vlink=#00004c alink=#eeeeee>
HEAD

$form = <<"FORM"
<b>全文検索</b>
<br><br>
<form action="./search.rb" method="get">
キーワード: <input type="text" name="keyword"><br>
    <input type="submit" value="検索">
</form>
<hr>
FORM

cgi = CGI.new('html4')
keyword = cgi.params['keyword'][0]
dir = cgi.params['dir'][0]

cgi.out(
        "type"	=> "text/html" ,
        "charset"	=> "Shift_JIS"
        ) do
  cgi.html do
    cgi.head{ cgi.title{'Search Engine'} } +
      cgi.body do
      if keyword
        $head + $form + search(keyword)
      else
        $head + $form
      end
    end
  end
end
