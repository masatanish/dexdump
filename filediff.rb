require 'cairo'
require 'ruby_apk'


if ARGV.size != 1 || !File.directory?(ARGV[0])
  $stderr.puts "Usage: #{$0} TARGET_DIRECTORY"
  exit
end

targets = Dir.glob(File.join(ARGV[0], "**/*"))

def datadiffimage(filename, d1, d2)
    width = 256
    height = ((d1.size/width) + 1) * 4
    surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, width, height)
    context = Cairo::Context.new(surface)
    (0...d1.size).step(4) do |addr|
      y = (addr / width) * 4
      x = (addr % width)
      color = (d1[addr] == d2[addr] ? Cairo::Color::WHITE : Cairo::Color::BLACK)
      context.set_source_color(color)
      context.rectangle(x,y, 4,4)
      context.fill
    end
    surface.write_to_png(filename)
end
targets.each do |p1|
  apk1 = Android::Apk.new(p1)
  dex1 = apk1.file('classes.dex')
  targets.each do |p2|
    next if p1== p2
    apk2 = Android::Apk.new(p2)
    dex2 = apk2.file('classes.dex')
    name = "#{File.basename(p1)[0..5]}-#{File.basename(p2)[0..5]}.png"
   datadiffimage(name, dex1, dex2)
  end
end

