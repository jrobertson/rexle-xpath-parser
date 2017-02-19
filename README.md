# Introducing the Rexle-xpath-parser gem

    require 'rexle-xpath-parser'


    xpath = "b[@color='red']"
    a = RexleXPathParser.new(xpath).to_a

    #=> [[:select, "b"], [:predicate, [[:attribute, "color"], [:value, :==, "red"]]]]

In the above example the parsed xpath instruction results in array with the first instruction to select the element *b*. The 2nd instruction is a predicate which contains a nested array of instructions. The predicates's 1st instruction is to select the attribute called *color* and then determine if the attribute value is equal to "red".

Note: This gem is experimental and is currently under developement.

## Resources

* rexle-xpath-parser https://rubygems.org/gems/rexle-xpath-parser

xpath rexle gem parser rexlexpathparser
