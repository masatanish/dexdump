require 'ruby_apk'

module Android
  class Dex

    class DexObject
      attr_reader :offset

      class StringDataItem
        def size
          @params[:utf16_size] + @size
        end
      end
    end
    attr_reader :header
    attr_reader :map_list
    attr_reader :string_ids
    attr_reader :string_data_items
    attr_reader :type_ids
    attr_reader :proto_ids
    attr_reader :method_ids
    attr_reader :class_defs
  end
end

class DexMap
  attr_reader :base_ranges
  attr_reader :string_ranges, :class_data_ranges, :code_item_ranges

  def initialize(dex)
    @dex = dex
    parse
  end

  def area(address)
    k, v = @base_ranges.find{|k, v| v.include? address }
    if k == :data
      k, a = @array_ranges.find{|k, a| a.any?{|r| r.include? address} }
      return (k.nil? ? :data : k )
    else
      return k
    end
  end
  def parse
    @base_ranges = {}
    @base_ranges[:header] = range_of_dexobject(@dex.header)
    @base_ranges[:string_ids] = range_of_dexobject(@dex.string_ids)
    @base_ranges[:type_ids] = range_of_dexobject(@dex.type_ids)
    @base_ranges[:proto_ids] = range_of_array(@dex.proto_ids)
    @base_ranges[:field_ids] = range_of_array(@dex.field_ids)
    @base_ranges[:method_ids] = range_of_array(@dex.method_ids)
    @base_ranges[:class_defs] = range_of_array(@dex.class_defs)
    @base_ranges[:data] = range_with_size(@dex.h[:data_off], @dex.h[:data_size])

    @string_ranges = @dex.string_data_items.map{|s| range_of_dexobject(s)}

    @class_data_ranges = []
    @code_item_ranges = []
    @debug_info_ranges = []
    @try_item_ranges = []
    @dex.class_defs.each do |c|
      unless c.class_data_item.nil?
        cls_data = c.class_data_item
        @class_data_ranges << range_of_dexobject(cls_data)
        cls_data[:direct_methods].each do |m|
          unless m.code_item.nil?
            @code_item_ranges << range_of_dexobject(m.code_item)
            unless m.code_item.debug_info_item.nil?
              @debug_info_ranges << range_of_dexobject(m.code_item.debug_info_item)
            end
            if m.code_item[:tries_size] > 0
              @try_item_ranges += m.code_item[:tries].map{|t| range_of_dexobject(t) }
            end
          end
        end
        cls_data[:virtual_methods].each do |m|
          unless m.code_item.nil?
            @code_item_ranges << range_of_dexobject(m.code_item)
          end
        end
      end
    end
    @array_ranges = {
      :code_item => @code_item_ranges,
      :class_data => @class_data_ranges,
      :string => @string_ranges,
      :debug_info => @debug_info_ranges ,
      :try_item => @try_item_ranges,
    }
  end

  def range_of_array(arr)
    offset = arr.first.offset
    last = arr.last.offset + arr.last.size
    Range.new(offset, last, true)
  end
  def range_of_dexobject(obj)
    Range.new(obj.offset, obj.offset + obj.size, true)
  end
  def range_with_size(offset, size)
    Range.new(offset, offset + size, true)
  end
end

if __FILE__ == $0
  apk = Android::Apk.new(ARGV[0])
  dmap = DexMap.new(apk.dex)
  puts "file size: #{apk.dex.h[:file_size]}"
  dmap.base_ranges.each do |k, v|
    puts "%s: %#010x - %#010x (%d)" % [ k, v.begin, v.end-1, v.end-v.begin]
  end
=begin
  puts '-' * 10
  dmap.code_item_ranges.each do |v|
    puts "%#010x - %#010x (%d)" % [v.begin, v.end-1, v.end-v.begin]
  end
  puts '-' * 10
  dmap.class_data_ranges.each do |v|
    puts "%#010x - %#010x" % [v.begin, v.end]
  end
=end

  dmap.base_ranges[:data].step(8) do |addr|
    puts "%#010x: %s" % [ addr, dmap.area(addr)]
  end

end
