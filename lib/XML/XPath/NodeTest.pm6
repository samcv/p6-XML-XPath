use v6.c;
use XML::XPath::Evaluable;
use XML::XPath::Types;

class XML::XPath::NodeTest {
    has Type $.type = "node";
    has Str $.value;

    method evaluate-node(XML::Node $xml-node is copy, Axis $axis --> Array) {
        my $result = [];
        given $axis {
            when 'self' {
                if self!test-node($xml-node) {
                    # xpath can not return the document.
                    $result.push: $xml-node ~~ XML::Document ?? $xml-node.root !! $xml-node;
                }
            }
            when 'child' {
                my @nodes = self!get-children($xml-node);
                for @nodes -> $child {
                    $result.push: $child if self!test-node($child);
                }
            }
            when 'descendant' {
                self!walk-descendant($xml-node, $result);
            }
            when 'descendant-or-self' {
                $result.push: $xml-node if self!test-node($xml-node);
                self!walk-descendant($xml-node, $result);
            }
            when 'attribute' {
                for $xml-node.attribs.kv -> $key, $val {
                    if $.value eq '*' or $.value eq $key {
                        $result.push($val);
                    } else {
                        #$result.add();
                    }
                }
                say $result.perl;
                #$result = $result.trim: :to-list(True);
            }
            when 'parent' {
                my $parent = $xml-node.parent;
                if $parent.defined && not ( $parent ~~ XML::Document ) {
                    $result.push: $parent if self!test-node($parent);
                }
            }
            when 'ancestor' {
                while ($xml-node = $xml-node.parent) {
                    last if $xml-node ~~ XML::Document;
                    $result.push: $xml-node if self!test-node($xml-node);
                }
            }
            when 'ancestor-or-self' {
                $result.push: $xml-node if self!test-node($xml-node);
                while ($xml-node = $xml-node.parent) {
                    last if $xml-node ~~ XML::Document;
                    $result.push: $xml-node if self!test-node($xml-node);
                }
            }
            when 'following-sibling' {
                my @fs = self!get-following-siblings($xml-node);
                for @fs {
                    $result.push: $_ if self!test-node($_);
                }
            }
            when 'following' {
                my @fs = self!get-following($xml-node);
                for @fs {
                    $result.push: $_ if self!test-node($_);
                    self!walk-descendant($_, $result);
                }
            }
            when 'preceding-sibling' {
                my @fs = self!get-preceding-siblings($xml-node);
                for @fs {
                    $result.push: $_ if self!test-node($_);
                }
            }
            when 'preceding' {
                my @fs = self!get-preceding($xml-node);
                for @fs {
                    $result.push: $_ if self!test-node($_);
                    self!walk-descendant($_, $result);
                }
            }
            default {
                X::NYI.new(feature => "axis $_").throw;
            }
        }
        return $result;
    }

    method !get-preceding(XML::Node $xml-node is copy) {
        my @preceding;
        loop {
            my $parent = $xml-node.parent;
            last if $parent ~~ XML::Document;
            # document order!
            @preceding.prepend: self!get-preceding-siblings($xml-node);;
            $xml-node = $parent;
        }
        @preceding;
    }
    method !get-preceding-siblings(XML::Node $xml-node) {
        my $parent = $xml-node.parent;
        unless $parent ~~ XML::Document {
            my $pos = $parent.index-of($xml-node);
            return $parent[0 .. $pos-1].reverse;
        }
        return ();
    }

    method !get-following(XML::Node $xml-node is copy) {
        my @following;
        loop {
            my $parent = $xml-node.parent;
            last if $parent ~~ XML::Document;
            # document order!
            @following.append: self!get-following-siblings($xml-node);;
            $xml-node = $parent;
        }
        @following;
    }
    method !get-following-siblings(XML::Node $xml-node) {
        my $parent = $xml-node.parent;
        unless $parent ~~ XML::Document {
            my $pos = $parent.index-of($xml-node);
            return $parent.nodes[$pos+1 .. *];
        }
        return ();
    }

    method !get-children(XML::Node $xml-node) {
        my @nodes;
        if $xml-node ~~ XML::Document {
            @nodes.push: $xml-node.root;
        } elsif $xml-node ~~ XML::Element {
            @nodes.append: $xml-node.nodes;
        }
        return @nodes;
    }

    method !walk-descendant(XML::Node $node, Array $result) {
        my @nodes = self!get-children($node);
        for @nodes -> $child {
            $result.push: $child if self!test-node($child);
            self!walk-descendant($child, $result);
        }
    }

    method !test-node(XML::Node $node --> Bool) {
        my Bool $take = False;
        given $.type {
            when 'node' {
                if $.value ~~ Str:U {
                    $take = True;
                } elsif $.value eq '*' {
                    $take = $node ~~ XML::Element;
                } else {
                    if $node ~~ XML::Element {
                        if $.value.contains(':') {
                            my @values = $.value.split(/':'/);
                            my $ns     = @values[0];
                            my $name   = @values[1];
                            if %*NAMESPACES{ $ns }:exists {
                                $node.name    ~~ / [ (<-[:]>+) ':' ]?  (<-[:]>+)/;
                                my $node-ns   = $/[0];
                                my $node-name = $/[1];
                                my $uri       = $node-ns ?? $node.nsURI($node-ns) !! $node.nsURI();
                                $take = $uri eq %*NAMESPACES{ $ns } && $node-name eq $name;
                                say "Namespace $ns exists TAKE($take) node {$node.name}, $uri is $uri ";
                            } else {
                                $take = $node.name eq $.value;
                            }
                        } else {
                            $take = $node.name eq $.value;
                        }
                    }
                }
            }
            when 'text' {
                $take = $node ~~ XML::Text;
            }
            when 'comment' {
                $take = $node ~~ XML::Commend;
            }
            when 'processsing-instruction ' {
                if $.value {
                    $take = $node.data.starts-with($.value);
                } else {
                    $take = $node ~~ XML::PI;
                }
            }
        }
        return $take;
    }
}
