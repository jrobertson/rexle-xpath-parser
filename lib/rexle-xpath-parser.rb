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
  def functionalise(a, r2=[])

    a.inject(r2) do |r,x|

      return r << functionalise(x) if x.is_a? Array
      
      if /^(?<func>\w+)\(\)/ =~ x then
        r << func.to_sym
      elsif /^@(?<attribute>[\w\/]+)/ =~ x
        r << [[:attribute, attribute]]
      elsif x =~ /^\/\//
        r << [:recursive, *RexleXPathParser.new(x[2..-1]).to_a]                
      elsif x =~ /^[\w\/\*]+\[/
        
        epath, predicate, remainder = x.match(/^([^\[]+)\[([^\]]+)\](.*)/).captures

        r.concat epath.split('/').map {|e| [:select, e]} << \
            [:predicate, RexleXPathParser.new(predicate).to_a] 

        
        if remainder.length > 0 then
          remainder.slice!(0) if remainder[0] == '/'          
          r << functionalise(match(remainder))
        else
          r
        end
        
        
      elsif x =~ /=/  
        r[-1] << [:value, :==, x[/=(.*)/,1].sub(/^["'](.*)["']$/,'\1')]
      elsif x =~ /\|/
        r << [:union] 
      elsif x =~ /\w+\(/
        r << [x.chop.to_sym]
      elsif x =~ /\d+/
        r << [:index, x]
      elsif /^attribute::(?<attribute>\w+)/ =~ x
        r << [:attribute, attribute]        
      elsif /^(?<name>[\w\*]+)\/?/ =~ x
        
        x.slice!(/^[\w\*]+\/?/)
        r3 = [[:select, name]]

        if x.length > 0 then
          functionalise([x], r3) 

        end
        r << r3        

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

    #puts 's: ' + s.inspect
    # e.g. position()
    if /^\w+\(\)$/ =~ s then
      a << s
    elsif s =~ /^\w+\(/ 

      found, token, remainder = lmatch(s.chars, '(',')')

      if found == ')' then
        a << token
      end

    # e.g. b[c='45']
    elsif s =~ /^[\w\/\*]+\[/

      found, token, remainder = lmatch(s.chars, '[',']') 
      a << token
      a2 = match remainder

      token << a2.first if  a2.first 
      a.concat a2[1..-1]

      a2
    elsif /^(?<name>[\w\*]+)\// =~ s
      a << name <<  match($')
    else

      token = s.slice!(/^[@?\w\/:\*\(\)]+/)
      a << token
      remainder = s
    end

    return a if remainder.nil? or remainder.empty?

    operator = remainder.slice!(/^\s*\|\s*/)

    if operator then
      a.concat [operator, *match(remainder)]
    else
      a << remainder
    end
    
    a
  end


  # accepts a token and drills into it to identify more tokens beneath it
  #
  def scan(s)

    if s =~ /^\w+\(/ then
      
      func = s.slice!(/\w+\(/)
      remainder = s[0..-2]

      return func if remainder.empty?
      
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