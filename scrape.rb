require "fileutils"
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'pry'
require 'pp'

HERE = File.split( __FILE__ )[0]
LOGDIR = File.join( HERE, "logs" )
def mhlw_url
  "https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00086.html"
end

def parse( html )
end

def asciinum(s)
  s.tr( "０１２３４５６７８９","0123456789" )
end

def jtoi(s)
  return s if Integer===s
  asciinum(s).to_i
end

def makerow(y,m,d,nums)
  cases = asciinum(nums).scan( /\d+/).map(&:to_i)
  [ jtoi(y), jtoi(m), jtoi(d), cases.size ] + cases
end

def write( data )
  fn = Time.now.strftime( "%Y_%M_%d_%H_%m" )
  FileUtils.mkdir_p( LOGDIR )
  CSV.open( "#{LOGDIR}/#{fn}.csv", "w" ) do |csv|
    csv << %w( year month day count cases )
    data.each do |row|
      csv << row
    end
  end
end

def main
  html = open(mhlw_url) do |f|
    f.set_encoding("utf-8")
    f.read
  end
  renum = "０１２３４５６７８９0123456789"
  data = []
  pat0 = %r![\(（]([#{renum}]+)月([#{renum}]+)日公表分[\)）].{0,10}（国内死亡\s*(.{1,20})例目!
  html.scan(pat0) do |m|
    data.push(makerow(2020,*(0..2).map{ |e| m[e] }))
  end
  pat1 =  %r!([#{renum}]+)年([#{renum}]+)月([#{renum}]+)日[^年月日]{50,400}死亡(.{1,20})例!
  html.scan(pat1) do |m|
    data.push(makerow(*(0..3).map{ |e| m[e] }))
  end
  write( data.sort )
end

main
