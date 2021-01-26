require 'ractor/tvar'

module Lee
  class TSolver < Solver
    def initialize(board, parallelism)
      @board = board
      @parallelism = parallelism

      @obstructed = Lee::Matrix.new(board.height, board.width)
      @board.pads.each do |pad|
        @obstructed[pad.y, pad.x] = 1
      end

      # Would be good if we could have TArray and TMatrix instead of a Matrix of TVars!
      @depth = Lee::Matrix.new(board.height, board.width) { Ractor::TVar.new(0) }
    end

    def solve
      # The worklist Ractor yields routes to solve
      worklist_ractor = Ractor.new(@board.routes) do |routes|
        routes.each do |route|
          Ractor.yield route
        end
        close_outgoing
      end

      # The solutions Ractor recieves solved routes and yields a map of solutions
      solutions_ractor = Ractor.new(@board.routes.size) do |count|
        solutions = {}
        count.times do
          key, value = Ractor.receive
          solutions[key] = value
        end
        Ractor.yield solutions
      end
      
      # Worker Ractors take a route from the worklist Ractor and send a solution to the solutions Ractor
      @parallelism.times.map {
        Ractor.new(self,   worklist_ractor, solutions_ractor) {
                  |solver, worklist_ractor, solutions_ractor|
          loop do
            route = worklist_ractor.take
      
            # Solving reads and writes the @depth matrix so it done atomically
            solution = Ractor.atomically do
              cost = solver.expand_route(route)
              solution = solver.solve_route(route, cost)
              solver.lay_route solution
              solution
            end

            solutions_ractor << [route, solution]
          end
        }
      }
      
      solutions_ractor.take
    end

    def expand_route(route)
      start_point = route.a
      end_point = route.b
    
      # From benchmarking - we're better of allocating a new cost-matrix each time rather than zeroing
      cost = Lee::Matrix.new(@board.height, @board.width)
      cost[start_point.y, start_point.x] = 1
    
      wavefront = [start_point]
    
      loop do
        new_wavefront = []
    
        wavefront.each do |point|
          point_cost = cost[point.y, point.x]
          Lee.adjacent(@board, point).each do |adjacent|
            next if @obstructed[adjacent.y, adjacent.x] == 1 && adjacent != route.b
            current_cost = cost[adjacent.y, adjacent.x]
            new_cost = point_cost + Lee.cost(@depth[adjacent.y, adjacent.x].value)
            if current_cost == 0 || new_cost < current_cost
              cost[adjacent.y, adjacent.x] = new_cost
              new_wavefront.push adjacent
            end
          end
        end
    
        raise 'stuck' if new_wavefront.empty?
        break if cost[end_point.y, end_point.x] > 0 && cost[end_point.y, end_point.x] < new_wavefront.map { |marked| cost[marked.y, marked.x] }.min
    
        wavefront = new_wavefront
      end
    
      cost
    end
    
    def solve_route(route, cost)
      start_point = route.b
      end_point = route.a
    
      solution = [start_point]
    
      loop do
        adjacent = Lee.adjacent(@board, solution.last)
        lowest_cost = adjacent
          .reject { |a| cost[a.y, a.x].zero? }
          .min_by { |a| cost[a.y, a.x] }
        solution.push lowest_cost
        break if lowest_cost == end_point
      end
    
      solution.reverse
    end
    
    def lay_route(solution)
      solution.each do |point|
        @depth[point.y, point.x].increment
      end
    end
  end
end
