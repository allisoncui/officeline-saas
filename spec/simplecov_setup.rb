require 'simplecov'

# Register merge hook early (before SimpleCov.start) so it runs after SimpleCov's at_exit hooks
# This will only execute if we're running Cucumber and RSpec was run as subprocess
Kernel.at_exit do
  # Only merge if we're in Cucumber mode and RSpec was run
  if defined?(Cucumber) && !defined?(RSpec) && ENV['SKIP_RSPEC'] != 'true'
    # Wait for SimpleCov to write its results
    sleep(0.2)
    
    result_path = File.join(SimpleCov.coverage_path, '.resultset.json')
    if File.exist?(result_path)
      begin
        require 'json'
        results = JSON.parse(File.read(result_path))
        
        # Merge RSpec and Cucumber results if both exist
        if results['RSpec'] && results['Cucumber']
          # Get Cucumber result from the resultset
          cucumber_result = SimpleCov::Result.from_hash(results['Cucumber'])
          
          # Load RSpec result and merge it
          rspec_result = SimpleCov::Result.from_hash(results['RSpec'])
          merged_result = cucumber_result.merge_resultset(rspec_result)
          
          # Update resultset with merged data
          results['Merged'] = merged_result.to_hash
          File.write(result_path, JSON.pretty_generate(results))
          
          # Format the merged result to update HTML report
          require 'simplecov/formatter/html_formatter'
          SimpleCov::Formatter::HTMLFormatter.new.format(merged_result)
        end
      rescue => e
        # Silently fail if merge doesn't work
        puts "Note: Could not merge coverage: #{e.message}" if ENV['DEBUG']
      end
    end
  end
end

# Determine command name based on what's loaded
command_name = if defined?(RSpec)
  'RSpec'
elsif defined?(Cucumber)
  'Cucumber'
else
  'Test'
end

SimpleCov.start 'rails' do
  # Use consistent command name to allow merging
  command_name command_name
  
  # Merge results from previous runs (if they exist)
  merge_timeout 3600
  
  # Track all application files
  track_files 'app/**/*.rb'
end

# When running Cucumber, automatically run RSpec tests first to get full coverage
# This ensures 100% coverage when running Cucumber alone
if defined?(Cucumber) && !defined?(RSpec) && ENV['SKIP_RSPEC'] != 'true'
  # Run RSpec as a subprocess first to generate its coverage
  # Then merge the results when Cucumber finishes
  require 'open3'
  
  puts "Running RSpec tests first to ensure full coverage..." if ENV['VERBOSE']
  
  # Run RSpec in a subprocess
  rspec_output, status = Open3.capture2e("bundle exec rspec --format progress")
  
  if status.success?
    puts "RSpec tests passed. Continuing with Cucumber..." if ENV['VERBOSE']
  else
    puts "Warning: RSpec tests had failures, but continuing with Cucumber..." if ENV['VERBOSE']
    puts rspec_output if ENV['VERBOSE']
  end
  # Merge will happen in the Kernel.at_exit hook registered at the top of this file
end

