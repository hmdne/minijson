require 'spec_helper'

RSpec.describe MiniJSON do
  it "accepts numbers" do
    parse('1').should be 1
    parse('2378923794878349523789782934523').should be == 2378923794878349523789782934523 unless RUBY_ENGINE == 'opal'
    parse('1.0').should be 1.0
    parse('1.278523874').should be 1.278523874
    parse('1.234e13').should be 1.234e13
    parse('1.234e+13').should be 1.234e13
    parse('1.234e-13').should be 1.234e-13
    parse('-1').should be -1
    parse('-2378923794878349523789782934523').should be == -2378923794878349523789782934523 unless RUBY_ENGINE == 'opal'
    parse('-1.0').should be -1.0
    parse('-1.278523874').should be -1.278523874
    parse('-1.234e13').should be -1.234e13
    parse('-1.234e+13').should be -1.234e13
    parse('-1.234e-13').should be -1.234e-13
  end

  it "accepts strings" do
    parse('"test"').should be == "test"
    parse('"test\""').should be == "test\""
    parse('"t e s t"').should be == "t e s t"
    parse('"tes\tt"').should be == "tes\tt"
    parse('"te\n\t\rst"').should be == "te\n\t\rst"
    parse('"te\\\\\n\t\rst"').should be == "te\\\n\t\rst"
    parse('"te\u1234st"').should be == "te\u1234st"
    parse(' "te\u1234st" ').should be == "te\u1234st"
  end

  it "accepts simple values" do
    parse('true').should be true
    parse('false').should be false
    parse(' false ').should be false
    parse('null').should be nil
  end

  it "accepts arrays" do
    parse('[1]').should be == [1]
    parse('[1,2,3]').should be == [1,2,3]
    parse('[1,2,"test",3]').should be == [1,2,"test",3]
    parse(' [ 1 , 2 , " test " , 3 ] ').should be == [1,2," test ",3]
  end

  it "accepts hashes" do
    parse('{"a":"b"}').should be == {"a" => "b"}
    parse('{"a":"b","b":"c"}').should be == {"a" => "b", "b" => "c"}
    parse('{"b":"c","a":"b"}').should be == {"b" => "c", "a" => "b"}
    parse('{"b":5,"a":"a"}').should be == {"b" => 5, "a" => "a"}
    parse(' { " b " : 5 , "a" : " a " } ').should be == {" b " => 5, "a" => " a "}
  end

  it "accepts nested arrays" do
    parse('[1,[1],2,[3],4]').should be == [1,[1],2,[3],4]
    parse('[1,[[1]],2,[3],4]').should be == [1,[[1]],2,[3],4]
    parse('[1,[1],[["test"]],[3],4]').should be == [1,[1],[["test"]],[3],4]
    parse('[1,[2],[3,[4],5]]').should be == [1,[2],[3,[4],5]]
    parse(' [ 1 , [ 2 ] , [ 3 , [ 4 ] , 5 ] ] ').should be == [1,[2],[3,[4],5]]
  end

  it "accepts nested hashes" do
    parse('{"a":{"b":{"c":{"d":0}}}}').should be == {"a" => {"b" => {"c" => {"d" => 0}}}}
    parse(' { "a" : { "b" : { "c" : { "d" : 0 } } } } ').should be == {"a" => {"b" => {"c" => {"d" => 0}}}}
  end

  it "accepts arrays nested in hashes and hashes nested in arrays" do
    parse('{"a":[{"b":[{"c":0}]}]}').should be == {"a" => [{"b" => [{"c" => 0}]}]}
    parse(' { "a" : [ { "b" : [ { "c" : 0 } ] } ] } ').should be == {"a" => [{"b" => [{"c" => 0}]}]}
  end

  it "rejects invalid JSON" do
    %w/sadf [lol [:lol ] [[lol] [[1],,] [,]2 {"a": "5"} e [4} {a:5}/.each do |i|
      proc{ parse(i) }.should raise_error MiniJSON::ParserError
    end
  end

  it "accepts very large input in acceptable time" do
    str = "SDSDsd34xrsdsa" * 100000
    parse(%{[[[[["#{str}"]]]]]}).should be == [[[[[str]]]]]
  end
end
