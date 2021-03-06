use v6.c;

use Test;
use XML::XPath;

plan 3;

my $x = XML::XPath.new(xml => q:to/ENDXML/);
<AAA>
<SELECT>BBB</SELECT>
<BBB/>
<CCC/>
<DDD>
<BBB/>
</DDD>
</AAA>
ENDXML

my $set;
$set = $x.find('//*[ name() = /AAA/SELECT ]');
say "--";
say $set;
is $set.elems, 2, '2 nodes';
is $set[0].name, 'BBB', 'name is BBB';
is $set[1].name, 'BBB', 'name is BBB';

done-testing;
