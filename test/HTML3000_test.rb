require "test_helper"
Treetop.load File.join(File.dirname(__FILE__), '../lib/html3000/html3000')

class HTML3000Test < Test::Unit::TestCase
  include ParserTestHelper
  
  def setup
    @parser = HTML3000Parser.new
  end
  
  def test_element_name
    assert_parses('@content { }')
    assert_parses('@h1 { }')
    assert_parse_failure('@1h {}')
    assert_parse_failure('@h7 {}')
    assert_parse_failure('@h0 { }')
    assert_parse_failure('@h$ { }')
  end
  
  def test_ruby_parsing
    assert_parses("<% Object.class %>")
  end
  
  def test_ruby_with_block_parsing
    assert_parses("<% Object.new do %><% end %>")
    assert_parses("<% Object.new do %><%end%>")
    assert_parses("<% Object.new do %><%     end            %>")
    assert_parses("<%Object.new do%><% end %>")
    assert_parse_failure("<% Object.newdo %><% end %>")
    assert_parse_failure("<% Object.new do %>")
    assert_parse_failure("<% end %>")
  end
  
  def test_ruby_block_argument_parsing
    assert_parses("<% Object.new do |one| %><% end %>")
    assert_parses("<% Object.new do |one,two| %><% end %>")
    assert_parses("<% Object.new do |one,    two   | %><% end %>")
    assert_parses("<% Object.new do |one     ,two   | %><% end %>")
    assert_parses("<% Object.new do |     one    | %><% end %>")
    assert_parse_failure("<% Object.new do || %><% end %>")
    assert_parse_failure("<% Object.new do|one| %><% end %>")
    assert_parse_failure("<% Object.new do |one,| %><% end %>")
    assert_parse_failure("<% Object.new do |,one| %><% end %>")
    assert_parse_failure("<% Object.new do |one,two,three,| %><% end %>")  
  end
  
  def test_ruby_block_value
    to_parse = %q{
      <% [1,2,3].collect do |i| %>
          <% i %>
      <% end %>
    }
    assert_parses(to_parse)
    assert_parse_value(to_parse, "123")
  end
  
  def test_ruby_multiline_block_parsing
    assert_parses("
      <% Object.new do %>
        <% @ruby.is.here %>
      <% end %>
    ")
  end
  
  def test_ruby_block_parsing_with_nested_elements
    assert_parses('<% Object.new do %> "This is a string" <% end %>')
    assert_parses('<% Object.new do %> @html {} <% end %>')
    assert_parses('<% Object.new do %> @html { @tag {} } <% end %>')
    assert_parses('<% Object.new do %> <% Object.methods.size %> <% end %>')
  end
  
  def test_parsing_with_newlines
    to_parse = <<-3000.chomp
      @html {
        @body { }
      }
      3000
    assert_parses(to_parse)
    to_parse = <<-3001.chomp
      @html {
        @body {
          #content {
            .login {
              @a[href:"google.com"] { "Login" }
            }
          }
        }
      }
      3001
      assert_parses(to_parse)
  end
  
  def test_parsing_siblings
    to_parse = <<-3001.chomp
      @html {
        @body { }
        @content { }
      }
      3001
    assert_parses(to_parse)
    to_parse = <<-3001.chomp
      @html {
        .body { }
        #content { }
      }
      3001
    assert_parses(to_parse)
    to_parse = <<-3001.chomp
      @html {
        .body { <% Object.class %> }
        #content { "Hello World" }
      }
      3001
    assert_parses(to_parse)
    to_parse = <<-3001.chomp
      @html {
        .body { 
          @world { "Hello" }
        }
        #content { }
      }
      3001
    assert_parses(to_parse)
  end
  
  # def test_parsing_non_tag_siblings
  #   to_parse = <<-3001.chomp
  #       @world { 
  #         @p { }
  #         "Hello" 
  #       }
  #     3001
  #   assert_parses(to_parse)
  # end
  
  def test_parsing_siblings_value
    to_parse = <<-3002.chomp
      @html {
        @body { }
        @content { }
      }
      3002
    assert_parse_value to_parse, "<html><body></body><content></content></html>"
  end
  
  def test_ruby_value
    assert_parse_value "<% Object.class %>", "Class"
    assert_parse_value "<% 1 + 2 %>", "3"
    assert_parse_value "<% 1 * 2 %>", "2"
    assert_parse_value "<% nil %>", ""
  end

  
def test_attributes_parsing_on_standard_elements
    assert_parses('@content[key:"value"] { }')
    assert_parses('@content[key:"value"] {}')
    assert_parses('@content[key:"value";another:"value"] {}')
    assert_parses('@content[key:"value"; another:"value"] {}')
    assert_parse_failure('@content[key:"value] {}')
    assert_parse_failure('@content[key:value] {}')
    assert_parse_failure('@content[key] {}')
    assert_parse_failure('@content["value"] {}')
  end
  
  def test_attributes_parsing_on_div_elements
    assert_parses('.content[key:"value"] {}')
    assert_parses('#content[key:"value"] {}')
    assert_parses('#content[key:"value";another:"value"] {}')
    assert_parses('.content[key:"value"; another:"value"] {}')
    assert_parse_failure('#content[key:"value] {}')
    assert_parse_failure('.content[key:value] {}')
    assert_parse_failure('#content[key] {}')
    assert_parse_failure('.content["value"] {}')
  end

  def test_attributes_value_on_standard_elements
    assert_parse_value '@em[key:"value"] {}', "<em key='value'></em>"
  end
  
  def test_multiple_attributes_value
    assert_parse_value '@em[key:"value";hello:"world"] {}', "<em key='value' hello='world'></em>"
    assert_parse_value '@em[key:"value";hello:"world"] { "Hello World" }', "<em key='value' hello='world'>Hello World</em>"
    assert_parse_value '.em[key:"value";hello:"world"] { "Hello World" }', "<div class='em' key='value' hello='world'>Hello World</div>"
  end

  def test_div_with_class
    assert_parses('.content{}')
    assert_parses('.content { }')
    assert_parses('.content {}')
    assert_parse_failure('.content')
    assert_parse_failure('blah.content {}')
    assert_parse_failure('....content {}')
  end
  
  def test_div_with_id
    assert_parses('#content {}')
    assert_parse_failure('#content')
    assert_parse_failure('# content {}')
  end
  
  def test_string
    assert_parses('"hello world"')
  end
  
  def test_any_html_element
    assert_parses("@strong {}")
    assert_parses("@strong { @em {} }")
    assert_parses('@strong { @em { "This be a string" } }')
    assert_parses('@em { @h1 { "This is the Title Text" } }')
    assert_parse_failure("@@strong")
    assert_parse_failure("@ strong")
    assert_parse_failure("@Strong")
    assert_parse_failure("@really_strong")
  end
  
  def test_any_html_element_value
    assert_parse_value "@strong {}", "<strong></strong>"
    assert_parse_value '@em { @h1 { "This is the Title Text" } }', "<em><h1>This is the Title Text</h1></em>"
  end
  
  def test_div_with_nesting
    assert_parses(".content { }")
    assert_parses('.content { "some tex" }')
    assert_parses(".content { .anothercontent { } }")
    assert_parses(".content { .anothercontent { .contentagain { } } }")
    assert_parses("#content { #anothercontent { #contentagain { } } }")
    assert_parses("#content { .anothercontent { #contentagain {} } }")
    assert_parse_failure("#content { blah blah }")
    assert_parse_failure("#content {")
    assert_parse_failure("#content {}}")
    assert_parse_failure("#content {{{}}")
  end
  
  def test_div_class_value
    assert_parse_value ".content {}", "<div class='content'></div>"
    assert_parse_value '.content { "hello world" }', "<div class='content'>hello world</div>"
    assert_parse_value '.content { .again {} }', "<div class='content'><div class='again'></div></div>"
    assert_parse_value '.content { .again { "hello world" } }', "<div class='content'><div class='again'>hello world</div></div>"
  end
  
  def test_div_id_value
    assert_parse_value "#content {}", "<div id='content'></div>"
    assert_parse_value '#content { "hello world" }', "<div id='content'>hello world</div>"
    assert_parse_value '#content { #again {} }', "<div id='content'><div id='again'></div></div>"
    assert_parse_value '#content { #again { "hello world" } }', "<div id='content'><div id='again'>hello world</div></div>"
  end
  
  def test_div_class_and_id_value
    assert_parse_value '#content { .again { "hello world" } }', "<div id='content'><div class='again'>hello world</div></div>"
  end
      
  def assert_parse_value(to_parse, expect)
    assert_equal parse(to_parse).value(binding), expect
  end
  
  def assert_parses(input)
    assert !parse(input).nil?
  end
  
  def assert_parse_failure(input)
    assert parse(input).nil?
  end
  
end