#version 0.2
#grosser.michael>AT<gmail>DOT<com
#code.google.com/p/agiledox-rake

class AgileDox
  def initialize options
    @options = options
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
  
  def write?
    @options.include? '--write'
  end

  #write comment to matching file in app/
  def write_comment_block file, lines
    return unless write?
    
    #target file exists ?
    file = test_file_to_app_file file
    return if file == false #could not translate to app file
    
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

  def process_tests file_selector
    tests = FileList[file_selector]
    tests.each do |file|
      lines = []
      
      #process lines
      File.foreach(file) do |line|
        string = '(\'|"){0,1}(.*?)\\1{0,1}'#matches User and '"my" User'
        case line
           #test
          when /^\s*class ([A-Za-z]+)Test/
            lines << class_name($1)
          when /^\s*def test_([A-Za-z_]+)/
            lines << "  - #{$1.gsub(/_/, ' ')}"
            
           #spec
          when /^\s*describe #{string} do/
            lines << class_name($2)
          when /^\s*it #{string} do/
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
          when /^\s*class ([A-Za-z]+)Test/
            lines << class_name($1 + "'s")
          when /^\s*def test_([A-Za-z]+)_([A-Za-z_]+)/
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
end

#TODO redundancy my ass... 
#generate rake task from an array of file_selectors

#call via rake dox:xxx
namespace :dox do
  #test
  task :units =>        'test:dox:units'
  task :functionals => 'test:dox:functionals'
  task :integration => 'test:dox:integration'
  
  #spec
  task :models =>       'spec:dox:models'
  task :controllers =>  'spec:dox:controllers'
  task :views =>        'spec:dox:views'
  task :helpers =>      'spec:dox:helpers'
end
task :dox => ['dox:units', 'dox:functionals','dox:models','dox:controllers','dox:views','dox:helpers']

#call via test:dox:xxx or spec:dox:xxx
dox = AgileDox.new [] #TODO no writing for now...
namespace :test do
  task :dox => ['dox:units', 'dox:functionals']
  namespace :dox do
    task :units do
      dox.process_tests 'test/unit/**/*_test.rb'
    end
    task :functionals do
      dox.process_tests_with_nested_actions 'test/functional/**/*_test.rb'
    end
    task :integration do
      dox.process_tests 'test/integration/**/*_test.rb'
    end
  end
end

namespace :spec do
  task :dox => ['dox:models', 'dox:controllers','dox:views','dox:helpers']
  namespace :dox do
    task :models do
      dox.process_tests 'spec/models/**/*_spec.rb'
    end
    
    task :controllers do
      dox.process_tests 'spec/controllers/**/*_spec.rb'
    end
      
    task :views do
      dox.process_tests 'spec/views/**/*_spec.rb'
    end
  
    task :helpers do
      dox.process_tests 'spec/helpers/**/*_spec.rb'
    end
  end
end