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
  renum = "[０１２３４５６７８９0123456789]+"
  html.scan( %r!(#{renum})月(#{renum})日公表分!) do |m|
    p m
  end



end

main
