#--
#
# Author::    Jay Johnson 
# Copyright:: Copyright (c) 2015 Jay Johnson
# License::   Distributes under the same terms as Ruby
#
#++

# make sure this will run out of the lib directory
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'colorize'

require './logging'
require './card'
require './account'
require './payment_processor'

# Build out the required arguments:
debug           = false
processor       = PaymentProcessor.new(debug)

usage_printout  = " \

    " + "Usage Help for Payment Processing".green + "

        To run in interactive mode use this command:
            ruby-luhn-checker-for-credit-card-validation/lib$ " + "ruby run_processor.rb".red + "\
        

        To perform the transactions listed inside a file use this command:
            ruby-luhn-checker-for-credit-card-validation/lib$ " + "ruby run_processor.rb <PATH TO INPUT FILE>".red + "\
\n
"

# Branch for supporting interactive mode or single-file mode
if ARGV.length >= 1
    path_to_file        = ""
    begin
        path_to_file    = ARGV[0].to_s

        # Suppor the help prompt
        if path_to_file == "help" or path_to_file == "--help" or path_to_file == "-h" or path_to_file == "--h"
            processor.lg(usage_printout, 6)
        else

            # allow debugging for fixing bugs
            if ARGV.length > 1
                if ARGV[1].to_s == "-d"
                    debug   = true
                    processor.enable_debug()
                end
            end

            # Does the file exist
            if File.file?(path_to_file)
                processor.dlg("Loading File: #{path_to_file}", 6)

                # Read in the file and process each line
                File.open(path_to_file, "r"){ |f|
                    f.each_line{ |line|
                        processor.process_action(line, debug)
                    }
                }
            
                # Build out the summary    
                current_summary = processor.run_report().to_s
                
                # Log it to stdout
                processor.lg(current_summary)
    
            else
                processor.lg("\nERROR: File Does Not Exist(#{path_to_file})\n\tPlease confirm it exists", 0)
                processor.lg(usage_printout, 6)
            end
        end

    rescue Exception => e
        processor.lg("\nERROR: Failed to Handle Arguments with Ex(#{e.message})\n", 0)
        return 0
    end

else
    processor.dlg("", 6)
    processor.dlg("Starting Interactive Shell Mode Please Type the Commands:", 5)
    processor.dlg("", 6)

    # Read input from stdin:
    while line = gets

        # Stop on empty line
        if line.to_s.chomp() == ""
            break
        else
            # Process this input
            processor.process_action(line.chomp(), debug)
        end
    end

    # Build out the summary    
    current_summary = processor.run_report().to_s
    
    # Log it to stdout
    processor.lg(current_summary)

end



