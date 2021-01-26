# Lee's Algorithm

This is *Lee's Algorithm* parallelised using Ractors and `TVar`.

See https://chrisseaton.com/truffleruby/ruby-stm/ and https://github.com/chrisseaton/ruby-stm-lee-demo.

```
% bundle exec ruby demo/lee/bench.rb
<internal:ractor>:267: warning: Ractor is experimental, and the behavior may change in future versions of Ruby! Also there are many implementation issues.
Validating...
Benchmarking...
Warming up --------------------------------------
          sequential     1.000  i/100ms
            ractor-1     1.000  i/100ms
            ractor-2     1.000  i/100ms
            ractor-4     1.000  i/100ms
Calculating -------------------------------------
          sequential      0.592  (± 0.0%) i/s -      3.000  in   5.072490s
            ractor-1      0.484  (± 0.0%) i/s -      3.000  in   6.198705s
            ractor-2      0.231  (± 0.0%) i/s -      2.000  in   8.676629s
            ractor-4      0.088  (± 0.0%) i/s -      1.000  in  11.348697s

Comparison:
          sequential:        0.6 i/s
            ractor-1:        0.5 i/s - 1.22x  (± 0.00) slower
            ractor-2:        0.2 i/s - 2.57x  (± 0.00) slower
            ractor-4:        0.1 i/s - 6.72x  (± 0.00) slower
```

What can we see here? At the moment using `TVar` adds a 1.22x overhead, which is reasonable. Using additional Ractors makes the benchmark run even slower. At the moment this is also reasonable, as Lee probably needs more advanced transactional features, such as conflict management and early release to work well. But it runs correctly!

### Sources

Inputs are from http://apt.cs.manchester.ac.uk/projects/TM/LeeBenchmark/, who in turn got them from Spiers [1]. They're described as 'typical production' boards but we're not sure where exactly they came from

> Unless otherwise mentioned, the code copyright is held by the University of Manchester, and the code is provided "as is" without any guarantees of any kind and is distributed as open source under a BSD license.

`inputs/minimal.txt` by Chris Seaton.

[1] T D Spiers and D A Edwards. A high performance routing engine. In Proceedings of the 24th ACM/IEEE conference on Design Automation, pages 793–799, 1987.

## Author

Written by Chris Seaton at Shopify, chris.seaton@shopify.com.

## License

MIT
