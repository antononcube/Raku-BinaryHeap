
use BinaryHeap:ver<0.1.0>;
#use BinaryHeap:ver<0.0.7>:auth<zef:dumarchie>:api<1>;

my \n    = 2**16;
my $heap = BinaryHeap.new: (^n).roll(n);
my $time = now;
for ^n {
    $heap.pop;
}
$time = now - $time;

printf "Pop value from heap (n = %d): %0.2fms\n", n, $time * 1000;
