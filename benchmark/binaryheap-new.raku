
use BinaryHeap:ver<0.1.0>;
#use BinaryHeap:ver<0.0.7>:auth<zef:dumarchie>:api<1>;

my \n      = 2**19;
my \values = (^n).roll(n);

my $time = now;
my $heap = BinaryHeap.new(values);
$time = now - $time;

printf "Create heap with multiple values (n = %d): %0.2fms\n", n, $time * 1000;
