require "fileutils"
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'pry'

HERE = File.split( __FILE__ )[0]

def mhlw_url
  "https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00086.html"
end

def parse( html )
end

def main
  html = open(mhlw_url) do |f|
    f.set_encoding("utf-8")
    f.read
  end
  renum = "０１２３４５６７８９0123456789"
  html.scan( %r![\(（]([#{renum}]+)月([#{renum}]+)日公表分[\)）].{0,10}（国内死亡\s*(.{1,20})例目!) do |m|
    p m
  end
  puts "-"*10
  html.scan( %r!([#{renum}]+)年([#{renum}]+)月([#{renum}]+)日[^年月日]{50,400}死亡(.{1,20})例!) do |m|
    p m
  end




end

main
