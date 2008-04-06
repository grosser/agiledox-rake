#version 0.4
#grosser.michael>AT<gmail>DOT<com
#code.google.com/p/agiledox-rake
#
#rake dox
#rake test:dox
#rake test:units:dox
#rake spec:models:dox

agiledox_options = {
  :write => false, #default: false
  :list_nested_actions => true, #for test:functionals, default: true
}


class AgileDox
  def initialize options
    @options = options
  end
  
  def process_tests file_selector
    tests = FileList[file_selector]
    tests.each do |file|
      needs_nesting?(file) ? process_with_nested_actions(file) : process_simple(file)
    end
  end
  
protected

  def needs_nesting? file
    @options[:list_nested_actions] && file =~ /test\/functional\//
  end
  
  def process_simple file
    lines = []
    #process lines
    File.foreach(file) do |line|
      string_rex = '(\'|"){0,1}(.*?)\\1{0,1}'#matches User and '"my" User'
      case line
         #test
        when /^\s*class ([^\s]+)Test/
          lines << class_name($1)
        when /^\s*def test_([^\s]+)/
          lines << "  - #{$1.gsub(/_/, ' ')}"
          
         #spec
        when /^\s*describe #{string_rex} do/
          lines << class_name($2)
        when /^\s*it #{string_rex} do/
          lines << "  - #{$2}"
      end
    end
    
    print_out lines
    write_comment_block file, lines
  end

  def process_with_nested_actions file
    lines = []
    actions = {}
    
    #process lines
    File.foreach(file) do |line|
      case line
        when /^\s*class ([^\s_]+)Test/
          lines << class_name($1 + "'s")
        when /^\s*def test_([^\s_]+)_([^\s]+)/
          actions[$1] ||= []
          actions[$1] << $2.gsub(/_/, ' ')
      end
    end
    
    #collect action results
    actions.each do |action,tests|
      lines << "  '#{action}' action:" 
      tests.each {|test| lines << "    - #{test}"}
    end
    
    print_out lines
    write_comment_block file,lines
  end

  def indefinite_article(word)
    (word.to_s.downcase =~ /^[aeoi]/) ? 'An' : 'A'
  end

  def class_name(class_name)
    name = class_name.to_s.gsub(/([A-Z])/, ' \1').strip
    "#{indefinite_article(class_name)} #{name}:" 
  end
  
  def test_file_to_app_file file
    translations = {
     'models'=>['unit','models'],
     'controllers'=>['functional','controllers']
    } 
    
    translations.each do |app_folder, test_folders|
      test_folders.each do |folder|
        rex = /(test|spec)\/#{folder}\/(.*)_\1.rb/
        next unless file =~ rex
        return file.sub!(rex) {"app/#{app_folder}/#{$2}.rb"}
      end
    end
    return false
  end
  
  #write comment to matching file in app/
  def write_comment_block file, lines
    return unless @options[:write]
    return if lines.size < 2 #no tests
    
    #target file exists ?
    file = test_file_to_app_file file
    return if file == false #could not translate to app file
    
    if !File.exists?(file) 
      puts "File: #{file} not found for comment insertion"
      return
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
end

#--------build tasks
list = {
  'spec'=>%w{models controllers views helpers},
  'test'=>%w{units functionals integration}
}

dox = AgileDox.new agiledox_options
list.each do |type,tasks|
  tasks.each do |sub_task|
    #REAL 
    #test:xxx:dox OR spec:xxx:dox
    namespace type do
      namespace sub_task do
        task :dox do
          folder = sub_task.sub(/(unit|functional)s/,'\1')#cut off 's'
          dox.process_tests "#{type}/#{folder}/**/*_#{type}.rb"
        end
      end
    end
    
    #LINKS
    #dox:xxx TO test:xxx:dox OR spec:xxx:dox
    real_task = "#{type}:#{sub_task}:dox"
    namespace :dox do
      task sub_task.intern => real_task 
    end
  end
  
  #general tasks test:dox
  namespace type do
    task :dox do
      dox.process_tests("#{type}/**/**/*_#{type}.rb")
    end
  end
end
    
task :dox => ['test:dox','spec:dox']