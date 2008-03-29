namespace :dox do
  def indefinite_article(word)
    (word.to_s.downcase =~ /^[aeoi]/) ? 'An' : 'A'
  end

  def class_name(class_name)
    class_name = class_name.to_s.gsub(/([A-Z])/, ' \1').strip
    "#{indefinite_article(class_name)} #{class_name}:" 
  end
  
  def test_file_to_app_file file
    #TODO SPEC
    translations = {
     'unit'=>'models',
     'functional'=>'controllers',
    } 
    
    translations.each do |test, app|
      rex = /test\/#{test}\/(.*)_test.rb/
      next unless file =~ rex
      return file.sub!(rex) {"app/#{app}/#{$1}.rb"}
    end
    return false
  end
  
  def write_comment file, lines
    #target file exists ?
    file = test_file_to_app_file file
    return if file == false
    
   if !File.exists?(file) 
      puts "File: #{file} not found for comment insertion"
     next
   end
   
    comment1 = "#AGILEDOX !WILL BE OVERWRITTEN!"
    comment2 = "#AGILEDOX END"
    
    #make content ready for replacement
    content = File.read(file)
    content = "#{comment1}#{comment2}\n" + content unless content.include?(comment1) #add comments if neccessary
    
    #replace
    File.open(file,'w') do |f|
      f << content.sub(/#{comment1}.*#{comment2}(.*)/m) {"#{comment1}\n##{lines.join("\n#")}\n#{comment2}#{$1}"}
    end
  end
  
  def print_out lines
    puts lines.join "\n"
  end

  task :units do
    tests = FileList['test/unit/*_test.rb']
    tests.each do |file|
      lines = []
      
      #captureing and printing
      File.foreach(file) do |line|
        case line
          when /^\s*class ([A-Za-z]+)Test/
            lines << class_name($1)
          when /^\s*def test_([A-Za-z_]+)/
            lines << "  - #{$1.gsub(/_/, ' ')}" 
        end
      end
      print_out lines
      
      write_comment file, lines
    end
  end

  task :functionals do
    tests = FileList['test/functional/*_test.rb']
    classes = {}
    current_class = nil
    print_actions = lambda do |actions|
      actions.each do |action, tests|
        puts "  '#{action}' action:" 
        tests.each {|test| puts "    - #{test}"}
      end
    end

    tests.each do |file|
      File.foreach(file) do |line|
        case line
          when /^\s*class ([A-Za-z]+)Test/
            classes[$1] = {}
            current_class = $1
          when /^\s*def test_([A-Za-z]+)_([A-Za-z_]+)/
            classes[current_class][$1] ||= []
            classes[current_class][$1] << $2.gsub(/_/, ' ')
        end
      end
    end
    classes.each do |class_name, actions|
      next if actions.nil? || actions.empty?

      print_class_name(class_name + "'s")
      print_actions.call actions
    end
  end
end

task :dox => ['dox:units', 'dox:functionals']
