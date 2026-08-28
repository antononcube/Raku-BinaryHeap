
use BinaryHeap:ver<0.1.0>;
#use BinaryHeap:ver<0.0.7>:auth<zef:dumarchie>:api<1>;

my \n      = 2**19;
my @values = (^n).roll(n);

my $heap = BinaryHeap.new;
my $time = now;
for @values {
    $heap.push: $_;
}
$time = now - $time;

printf "Push value onto heap (n = %d): %0.2fms\n", n, $time * 1000;
