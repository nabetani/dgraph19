require "fileutils"
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'pry'
require 'pp'
require 'digest'

HERE = File.split( __FILE__ )[0]
LOGDIR = File.join( HERE, "logs" )
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36"

def mhlw_url_until_march_end
  "https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00086.html"
end

def mhlw_url_after_april
  "https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/topics_shingata_09444.html"
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

def build(data)
  CSV.generate do |csv|
    csv << %w( year month day count cases )
    data.each do |row|
      csv << row
    end
  end
end

def write( data )
  fn = Time.now.strftime( "%Y_%m_%d_%H_%M" )
  FileUtils.mkdir_p( LOGDIR )
  text = build(data)
  last = File.open( Dir.glob( File.join(LOGDIR, "*.csv" ) ).max, &:read )
  if last == text 
    puts( "same to the last data" )
    return
  end
  path = "#{LOGDIR}/#{fn}.csv"
  File.open( path, "w" ) do |f|
    f.write( text )
  end
  puts( "created #{path}." )
end

def check_cases(data)
  nums = data.map{ |e| e.drop(4) }.flatten.sort
  first, last = nums.minmax
  if [*first..last] != nums
    $stderr.puts "minmax=(#{first}, #{last})"
    lost = [*first..last] - nums
    dupnum = nums.each_cons(2).select{ |a,b| a==b }
    $stderr.puts "#{lost.inspect} are missing case"
    $stderr.puts "#{dupnum.inspect} are dup case"
    raise "unexpected case"
  end
end

def get_after_april_html(url)
  open(url ) do |f|
    f.set_encoding("utf-8")
    f.read
  end
end

def renum
  "０１２３４５６７８９0123456789"
end


def get_after_april(url)
  html = get_after_april_html( "https://www.mhlw.go.jp"+url)
  doc = Nokogiri::HTML(html)
  text = doc.xpath("//div").first.text
  data=[]
  sum = nil
  text.scan(/([#{renum}]+)月([#{renum}]+)日[^\r\n]+死[^#{renum}]{0,10}([#{renum}]+)/) do |m|
    data.push( m.map{ |e| jtoi(e) } )
  end
  text.scan( /これまでに[^\r\n]+死[^#{renum}]{0,10}([#{renum}]+)/) do |m|
    sum = m.map{ |e| jtoi(e) }
  end
  return nil if data.empty?
  if 1 < data.uniq.size 
    raise data.inspect
  end
  s=[2020, *data[0], *sum]
  pp s
  s
end

def dayof(text)
  m=/([#{renum}]+)年([#{renum}]+)月([#{renum}]+)日\s*掲載/.match(text)
  return [0,0,0] unless m
  [1,2,3].map{ |e| jtoi(m[e]) }
end

def after_april
  html = get_after_april_html(mhlw_url_after_april)
  doc = Nokogiri::HTML(html)
  data = []
  doc.xpath("//a").each do |node|
    text = node.text
    next if (dayof(text)<=>[2020,4,1])<0
    next unless /患者等の発生/===text
    next if /空港検疫/===text
    data << get_after_april(node.attributes["href"].value)
  end
  data
end

def until_march_end
  html = open(mhlw_url_until_march_end) do |f|
    f.set_encoding("utf-8")
    f.read
  end
  data = []
  pat0 = %r![\(（]([#{renum}]+)月([#{renum}]+)日公表分[\)）].{0,10}（国内死亡\s*(.{1,20})例目!
  html.scan(pat0) do |m|
    data.push(makerow(2020,*(0..2).map{ |e| m[e] }))
  end
  pat1 =  %r!([#{renum}]+)年([#{renum}]+)月([#{renum}]+)日[^年月日]{50,400}死亡(.{1,20})例!
  html.scan(pat1) do |m|
    data.push(makerow(*(0..3).map{ |e| m[e] }))
  end
  check_cases(data)
  data
end

def main
  data = after_april + until_march_end
  write( data.sort )
end

main
