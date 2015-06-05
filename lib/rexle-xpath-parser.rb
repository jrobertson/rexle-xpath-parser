#!/usr/bin/env ruby

# file: rexle-xpath-parser.rb


class RexleXPathParser

  attr_reader :to_a

  def initialize(string)
    
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

    a.map do |x|

      if x =~ /\w+\[/ then
        epath, predicate = x.match(/^([^\[]+)\[([^\]]+)\]/).captures
        epath.split('/').map {|e| [:select, e]} + [:predicate, predicate]
      elsif x =~ /\|/
        [:union] 
      elsif x =~ /\w+\(/
        [x.chop.to_sym]
      elsif x =~ /\d+/
        [:index, x[1..-2]]
      elsif x =~ /[\w\/]+/
        x.split('/').map {|e| [:select, e]}
      elsif x.is_a? Array
        functionalise(x)
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

    if s =~ /^\w+\(/ then

      found, token, remainder = lmatch(s.chars, '(',')')

      if found == ')' then
        a << token
      end

    elsif s =~ /^[\w\/]+\[/

      found, token, remainder = lmatch(s.chars, '[',']') 
      a << token
      a2 = match remainder

      token << a2.first if  a2.first 
      a.concat a2[1..-1]

      a2

    else
      token = s.slice!(/^[\w\/]+/)
      a << token
      remainder = s
    end

    operator = remainder.slice!(/^\s*\|\s*/)

    if operator then
      a.concat [operator, *match(remainder)]
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