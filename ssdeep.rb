require 'ssdeep'
require 'ruby_apk'

ssdeep = {}

if ARGV.size != 1 || !File.directory?(ARGV[0])
  $stderr.puts "Usage: #{$0} TARGET_DIRECTORY"
  exit
end

puts 'ssdeep hash -------------'
Dir.glob(File.join(ARGV[0], "**/*")).each do |path|
  next unless File.file? path
  apk = Android::Apk.new(path)
  base=File.basename(path)
  deep = Ssdeep.from_string(apk.file('classes.dex'))
  puts "#{base[0..5]}...: '#{deep}'"
  ssdeep[base] = deep
end

puts 'ssdeep compare -----------'
ssdeep.each do |k,v|
  ssdeep.each do |l,u|
    puts "#{k[0..5]}:#{l[0..5]} => #{Ssdeep.compare(v,u)}" unless k == l
  end
  puts '----' * 10
end
