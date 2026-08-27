# A BinaryHeap is an implicit binary tree that satisfies the heap property:
# the value of a node never precedes the value of its parent node
role BinaryHeap {
    # The heap is represented by @!array[^$!elems];
    # the array may contain additional elements to accommodate a heapsort.
    has @!array;
    has int $!elems;
    has @!path; # reusable path for sift-down
    has Callable $!comparator;

    method comparison-order(--> Order:D) { Less }

    method !PRECEDES(Mu \left, Mu \right --> Bool:D) {
        ($!comparator.defined
          ?? $!comparator(left, right)
          !! left cmp right) == self.comparison-order;
    }

    method !SET-COMPARATOR(Callable:D $comparator) {
        $!comparator = $comparator;
        self;
    }

    method !CREATE-HEAP() {
        my \heap = self.CREATE;
        heap!SET-COMPARATOR($!comparator)
          if self.defined && $!comparator.defined;
        heap;
    }

    sub same-comparator(BinaryHeap \a, BinaryHeap \b --> Bool:D) {
        my \ours = get-comparator(a);
        my \theirs = get-comparator(b);
        ours.defined ?? theirs.defined && ours === theirs !! !theirs.defined;
    }

    sub get-comparator(BinaryHeap \heap) {
        return Callable unless heap.defined;
        heap.WHAT.^attributes.first(*.name eq '$!comparator').get_value(heap);
    }

    method !SET-SELF(@array) {
        @!array := @array;
        $!elems = @!array.elems;
        self;
    }

    # Clone a concrete heap
    multi method clone(BinaryHeap:D: --> BinaryHeap:D) {
        my @copy = @!array.head($!elems);
        self!CREATE-HEAP!SET-SELF(@copy);
    }

    # Construct a heap with zero or more values
    proto method new(|) {*}
    multi method new(::?CLASS:U: *@values, :&comparator --> BinaryHeap:D) {
        my \heap = self.CREATE;
        heap!SET-COMPARATOR(&comparator) if &comparator.defined;
        @values ?? heap!SET-SELF(@values.Array)!HEAPIFY !! heap;
    }

    # Heapify an array
    method heapify(@array --> BinaryHeap:D) {
        self!CREATE-HEAP!SET-SELF(@array)!HEAPIFY;
    }
    method !HEAPIFY() {
        my int $pos = ($!elems - 2) div 2; # last internal node
        self!sift-down($pos--) while $pos >= 0;
        self;
    }

    # Sift down with bounce to reduce the number of comparisons
    # Define a path down from a node at a given position, by selecting the
    # highest priority (or right) child at each level. Then shorten the path
    # until the final node can contain the value of the first node without
    # violating the heap condition. Then assign each node in the path the value
    # of its successor, and assign the final node the value of the first node.
    method !sift-down(int $pos is copy --> Nil) {
        my $node := @!array[$pos];
        @!path.BIND-POS(my int $path-end, $node);

        my int $heap-end = $!elems - 1;
        while ($pos = ($pos * 2) + 1) < $heap-end {
            my \left  = @!array[$pos];
            my \right = @!array[$pos + 1];
            if self!PRECEDES(left, right) {
                @!path.BIND-POS(++$path-end, left);
            }
            else {
                $pos += 1;
                @!path.BIND-POS(++$path-end, right);
            }
        }

        # at the deepest level there may be only one child
        if $pos == $heap-end {
            @!path.BIND-POS(++$path-end, @!array[$pos]);
        }

        # shorten the path until the final node can hold the value of the first
        my $value = $node;
        while $path-end > 0 && self!PRECEDES($value, @!path[$path-end]) {
            $path-end--;
        }

        # shift values until we reach the final node of the path
        $pos = 0;
        while $pos < $path-end {
            my \child = @!path[++$pos];
            $node  = child;
            $node := child;
        }

        # assign the original value of the first node to the final node
        $node = $value;
    }

    # Extract a single value from a heap
    method pop() {
        self ?? self!extract !! Failure.new:
          X::Cannot::Empty.new(:action<pop>, :what(self.^name));
    }
    method !extract() {
        my $value = @!array[$!elems - 1]:delete;
        --$!elems > 0 ?? self.replace($value) !! $value;
    }

    # Extract a Seq of values from a heap
    method consume( --> Seq:D) {
        gather take self!extract while self;
    }

    # Insert values into a heap
    proto method push(|) {*}
    multi method push(::?CLASS:U $_ is rw: **@values is raw --> BinaryHeap:D) {
        $_ = self!CREATE-HEAP.push(|@values);
    }
    multi method push(BinaryHeap:D: **@values is raw --> BinaryHeap:D) {
        self!insert($_) for @values;
        self;
    }
    multi method push(BinaryHeap:D: Slip \values --> BinaryHeap:D) {
        self!insert($_) for values;
        self;
    }
    multi method push(BinaryHeap:D: Mu \value --> BinaryHeap:D) {
        self!insert(value);
        self;
    }
    method !insert(Mu \value --> Nil) {
        # increment $!elems only if the value can be assigned to a new node
        my $node := @!array[$!elems];
        $node = value;
        my int $pos = $!elems++;

        # sift the provided value up from the new node
        while $pos > 0
          && self!PRECEDES(value,
               my \parent = @!array[$pos = ($pos - 1) div 2])
        {
            $node  = parent;
            $node := parent;
        }
        $node = value;
    }

    # Insert, then extract
    method push-pop(Mu \value) {
        self && self!PRECEDES(@!array[0], value)
          ?? self.replace(value) !! value;
    }

    # Replace the top of a heap (extract, then insert)
    method replace(\SELF: Mu \new) {
        if self {
            my $node := @!array[0];
            my $old = $node;
            $node = new;
            self!sift-down(0);
            $old;
        }
        else {
            SELF.push(new);
            Nil;
        }
    }

    proto method sort(|) {*}
    multi method sort(BinaryHeap:U:) { Array.new }
    multi method sort(BinaryHeap:D:) {
        my @array := @!array;
        while $!elems > 1 {
            my $node := @array[--$!elems];
            $node = self.replace($node);
        }
        self!SET-SELF(@array.new);
        @array;
    }

    method Bool( --> Bool:D) { self.defined && $!elems > 0 }
    method top() { self ?? @!array[0] !! Nil }

    # Allow introspection, but do not return containers:
    method values( --> Seq:D) {
        if self {
            my int $i;
            gather take @!array[$i++] while $i < $!elems;
        }
        else {
            Empty.Seq;
        }
    }

    multi sub infix:<eqv>(BinaryHeap \a, BinaryHeap \b --> Bool:D) is export {
        a.WHAT === b.WHAT
          && same-comparator(a, b)
          && a.values eqv b.values;
    }
}

class BinaryHeap::MaxHeap does BinaryHeap {
    method comparison-order(--> Order:D) { More }
}

class BinaryHeap::MinHeap does BinaryHeap {}

proto sub heapsort(|) is export {*}
multi sub heapsort(@array, :$reverse) {
    my \heap = $reverse ?? BinaryHeap::MinHeap !! BinaryHeap::MaxHeap;
    heap.heapify(@array).sort;
}
multi sub heapsort(&cmp, @array, :$reverse) {
    my \heap = $reverse ?? BinaryHeap::MinHeap !! BinaryHeap::MaxHeap;
    heap.new(:comparator(&cmp)).heapify(@array).sort;
}
