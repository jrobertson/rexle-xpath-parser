#!/usr/bin/env ruby

# file: rexle-xpath-parser.rb


class RexleXPathParser

  attr_reader :to_a

  def initialize(s)
    @to_a = scan(s.clone)
  end

  def scan(s2)

    if s2.lstrip[0] == '|' then    
      return [s2.slice!(/\s*\|\s*/).strip] 
    end

    s1 = s2.slice!(/\w+[\(\[]/)

    if s1[-1] == '[' then
      s1 << s2.slice!(/[^\]]+\]|\]/)
      return [s1]
    end

    if s2[/\w+[\(\[]/] then
      r = [scan(s2)]
      r << scan(s2) while s2[/\w+[\(\[]/]
      s3 = s2
    else
      s1 << s2.slice!(/[^\)\]]+[\)\]]|[\)\]]/)
    end

    [s1,r,s3].compact
  end
end
