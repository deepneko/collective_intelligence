#!/usr/bin/env ruby
require 'cgi'
require 'Searcher'

def search(keyword)
end

$head = <<"HEAD"
<html><head>
<title>File Search</title>
<style>
BODY, TD, TR{font-size:12px}
A{text-decoration:none}
</style>
</head>
<body bgcolor=#ffffff link=#00004c vlink=#00004c alink=#eeeeee>
HEAD

$form = <<"FORM"
<b>ファイルの検索</b>
<br><br>
<form action="./Explorer.rb" method="get">
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
    cgi.head{ cgi.title{'Search http://'} } +
      cgi.body do
      if keyword
        search(keyword)
      end
    end
  end
end
