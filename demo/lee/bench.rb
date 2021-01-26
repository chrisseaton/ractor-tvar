require 'benchmark/ips'

require_relative 'lib/lee'

# Trigger the Ractor warning early!
Ractor.new { }

board = Lee.read_board(File.expand_path('inputs/testBoard.txt', __dir__))

puts 'Validating...'

raise unless Lee.board_valid?(board)

solver = Lee::Solver.new(board)
solution = solver.solve
raise unless Lee.solution_valid?(board, solution)

1.upto(4) do |t|
  solver = Lee::TSolver.new(board, 1)
  solution = solver.solve
  raise unless Lee.solution_valid?(board, solution)
end

puts 'Benchmarking...'

Benchmark.ips do |x|
  # sequential solves without any parallelism, or overhead for being able to use parallelism

  x.report('sequential') do
    solver = Lee::Solver.new(board)
    solver.solve
  end

  # ractor-1 solves with the overhead for being able to use parallelism, but no actual parallelism

  x.report('ractor-1') do
    solver = Lee::TSolver.new(board, 1)
    solver.solve
  end

  # ractor-2 solves with 2-way parallelism

  x.report('ractor-2') do
    solver = Lee::TSolver.new(board, 2)
    solver.solve
  end

  # ractor-4 solves with 4-way parallelism - check you have enough actual cores to run this

  x.report('ractor-4') do
    solver = Lee::TSolver.new(board, 4)
    solver.solve
  end

  x.compare!
end
