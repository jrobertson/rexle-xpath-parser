#!/usr/bin/env ruby

# file: rexle-xpath-parser.rb


class RexleXPathParser

  attr_reader :to_a

  def initialize(string)
    #puts 'inside RExleXpathParser'
    tokens = tokenise string
    #puts 'tokens: ' + tokens.inspect
    nested_tokens = tokens.map {|x| scan(x)}
    #puts 'nested_tokens: ' + nested_tokens.inspect
    @to_a = functionalise nested_tokens
    
  end

  private
  
  # maps the nested tokens to XPath functions, predicates, operators, 
  #                                                      and 1 or more elements
  #  
  def functionalise(a)

    a.inject([]) do |r,x|

      #puts 'x: ' + x.inspect
      if x =~ /^@[\w\/]+/ then 
        r << [[:attribute, x[/@(\w+)/,1]]]
      elsif x =~ /[\w\/]+\[/
        
        epath, predicate, remainder = x.match(/^([^\[]+)\[([^\]]+)\](.*)/).captures
        
        if remainder.length > 0 then
          remainder.slice!(0) if remainder[0] == '/'          
          r << functionalise(match(remainder))
        else
          r
        end
        
        epath.split('/').map {|e| [:select, e]} << \
            [:predicate, RexleXPathParser.new(predicate).to_a] + r
        
      elsif x =~ /=/  
        r[-1] << [:value, :==, x[/=(.*)/,1].sub(/^["'](.*)["']$/,'\1')]
      elsif x =~ /\|/
        r << [:union] 
      elsif x =~ /\w+\(/
        r << [x.chop.to_sym]
      elsif x =~ /\d+/
        r << [:index, x[1..-2]]
      elsif x =~ /^\/\//
        r << [:recursive, *RexleXPathParser.new(x[2..-1]).to_a]        
      elsif x.is_a? Array
        r << functionalise(x)        
      elsif /^attribute::(?<attribute>\w+)/ =~ x
        r << [:attribute, attribute]        
      elsif x =~ /[\w\/]+/
        r << x.split('/').map {|e| [:select, e]}

      end
    
    end

  end
  
  # matches a left bracket with a right bracket recursively if necessary
  #
  def lmatch(a, lchar, rchar)

    token = []
    c = a.first
    token << c until (c = a.shift; c == lchar or c == rchar or a.empty?)
    token << c

    if c == lchar then
      found, tokenx, remainderx = rmatch(a, lchar, rchar)
      c = found
      token << tokenx
      remainder = remainderx
    else
      remainder = a.join
    end

    [c, token.join, remainder]
  end

  
  # matches a right bracket for a left bracket which has already been found. 
  #
  def rmatch(a, lchar, rchar)

    token = []
    c = a.first
    token << c until (c = a.shift; c == lchar or c == rchar or a.empty?)
    token << c

    if c == lchar then
      
      found, tokenx, remainderx = rmatch(a, lchar, rchar)
      token << tokenx

      # find the rmatch for the starting token
      found, tokenx, remainderx = rmatch(a, lchar, rchar)        
      c = found
      token << tokenx
      remainder = remainderx
      
    elsif c = rchar
      remainder = a.join
    end

    [c, token.join, remainder]
  end

  # tokeniser e.g. "a | d(c)" #=> ["a", " | ", "d(c)"] 
  #
  def match(s)

    a = []

    # e.g. position()
    if s =~ /^\w+\(/ then

      found, token, remainder = lmatch(s.chars, '(',')')

      if found == ')' then
        a << token
      end

    # e.g. b[c='45']
    elsif s =~ /^[\w\/]+\[/

      found, token, remainder = lmatch(s.chars, '[',']') 
      a << token
      a2 = match remainder

      token << a2.first if  a2.first 
      a.concat a2[1..-1]

      a2

    else
      token = s.slice!(/^[@?\w\/:]+/)
      a << token
      remainder = s
    end

    operator = remainder.slice!(/^\s*\|\s*/)

    if operator then
      a.concat [operator, *match(remainder)]
    else
      a << remainder if remainder.length > 0
    end
    
    a
  end


  # accepts a token and drills into it to identify more tokens beneath it
  #
  def scan(s)

    if s =~ /^\w+\(/ then
      func = s.slice!(/\w+\(/)
      remainder = s[0..-2]
      if remainder =~ /^\w+\(/ then
        scan(remainder)
      else
        [func, match(remainder)]
      end
    else
      s
    end
  end
      
  alias tokenise match  
      
  
end
