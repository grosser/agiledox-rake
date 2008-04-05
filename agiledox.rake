#version 0.3
#grosser.michael>AT<gmail>DOT<com
#code.google.com/p/agiledox-rake
agiledox_options = {
  :write => true,
  :list_nested_actions => true, #for test:functionals
}


class AgileDox
  def initialize options
    @options = options
  end
  
  def process_tests file_selector
    tests = FileList[file_selector]
    tests.each do |file|
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
  end

  def process_tests_with_nested_actions file_selector
    test_files = FileList[file_selector]
    #collect dox for every action
    test_files.each do |file|
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
  end

protected

  def indefinite_article(word)
    (word.to_s.downcase =~ /^[aeoi]/) ? 'An' : 'A'
  end

  def class_name(class_name)
    name = class_name.to_s.gsub(/([A-Z])/, ' \1').strip
    "#{indefinite_article(class_name)} #{name}:" 
  end
  
  def test_file_to_app_file file
    translations = {
      #test
     'unit'=>'models',
     'functional'=>'controllers',
     
     #spec
     'models'=>'models',
     'controllers'=>'controllers',
    } 
    
    translations.each do |test, app|
      rex = /(test|spec)\/#{test}\/(.*)_\1.rb/
      next unless file =~ rex
      return file.sub!(rex) {"app/#{app}/#{$2}.rb"}
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

all_tasks = []
list.each do |type,tasks|
  tasks.each do |sub_task|
    #REAL 
    #test:xxx:dox OR spec:xxx:dox
    namespace type do
      namespace sub_task do
        task :dox do
          folder = sub_task.sub(/(unit|functional)s/,'\1')#cut off 's'
          file_selector = "#{type}/#{folder}/**/*_#{type}.rb"
          
          dox = AgileDox.new agiledox_options
          folder == 'functional' && agiledox_options[:list_nested_actions] ? 
            dox.process_tests_with_nested_actions(file_selector) : 
            dox.process_tests(file_selector)  
        end
      end
    end
    
    #LINKS
    #dox:xxx TO test:xxx:dox OR spec:xxx:dox
    real_task = "#{type}:#{sub_task}:dox"
    namespace :dox do
      task sub_task.intern => real_task 
    end
    
    all_tasks << real_task
  end
  
  #collective tasks test:dox = test:units:dox + test:functionals:dox + ...
  namespace type do
    task :dox => tasks.collect {|x| "#{x}:dox"}
  end
end
    
task :dox => all_tasks