require "card"
require "account"
require "payment_processor"

card_tests          = [
                        {
                            "Name"      => "Greg",
                            "Card"      => "4111111111111111",
                            "Balance"   => "1000"
                        }
                    ]

test_debug          = false            
new_processor       = PaymentProcessor.new()

describe PaymentProcessor do

  describe "add" do
    context "will create a new credit card for a given name, card number, and limit" do
      it "will add a credit card with start limit" do
        new_processor.add("Greg", "4111111111111111", "$1000")
      end
    end
  end

  describe "credit" do
    context "credit the card balance" do
      it "will add a credit to the account" do
        new_processor.credit("Greg", "$500")
      end
    end
  end

  describe "credit" do
    context "credit the card balance" do
      it "will add a credit to the account" do
        new_processor.credit("Greg", "$500")
      end
    end
  end

  describe "credit" do
    context "try to credit an inactive card" do
      it "credit an inactive card" do
        expect(new_processor.credit("Greg", "$500", "NOT A REAL CARD")).to be 1
      end
    end
  end

  describe "summary" do
    context "build a summary report" do
      it "will display the account balances" do
        test_report = new_processor.run_report()

        if test_debug
            new_processor.lg(test_report) 
        end
      end
    end
  end

  describe "charge" do
    context "try to charge Greg's card" do
      it "charge the card" do
        expect(new_processor.charge("Greg", "$800")).to be 0
      end
    end
  end

  describe "overcharge" do
    context "try to overcharge Greg's card" do
      it "overcharge the card" do
        expect(new_processor.charge("Greg", "$1800")).to be 1
      end
    end
  end

  describe "full summary"
    context "try to run all test input file simulations" do
      it "will validate the input files match the expected output" do

        # Build out the test file array by assuming the test files have a prefix and numbering convention
        test_files                  = []
        test_file_dir               = "./spec"
        Dir.glob(test_file_dir + "/input_*.txt") { |file|
            input_file_name         = ""
            output_file_name        = ""
        
            if file.include?("input")
                new_node            = {
                                    "Input"     => "Not Real",
                                    "Output"    => "Not Real"
                                    }
                input_file_name     = file.to_s
                new_node["Input"]   = input_file_name
                new_node["Output"]  = test_file_dir + "/output_" + input_file_name.split("_")[1]
                test_files.push(new_node)
            end
        }

        # For each test file make sure to rebuild the PaymentProcessor and simulate the input to verify that it
        # matches the output
        test_files.each{ |test| 

            test_input_file         = test["Input"]
            test_output_file        = test["Output"]

            test_object             = PaymentProcessor.new()

            File.open(test_input_file, "r"){ |f|
                f.each_line{ |line|
                    test_object.process_action(line, test_debug)
                }
            }

            current_summary         = test_object.run_report().to_s
            summary_lines           = current_summary.split("\n")

            if test_debug
                puts "SummaryLines(#{summary_lines.length}) Input(#{test_input_file}) Output(#{test_output_file})"
            end

            test_output_lines       = []
            File.open(test_output_file, "r") { |outputfile|
                outputfile.each_line { |test_output_line|
                    test_output_lines.push(test_output_line)
                }
            }

            expect(summary_lines.length).to eq(test_output_lines.length)

            cur_idx                 = 0
            test_object.dlg("Testing File(#{test_input_file.to_s})", 6)
            while cur_idx < test_output_lines.length
                cur_summary_line    = summary_lines[cur_idx]
                test_output_line    = test_output_lines[cur_idx]

                expect(cur_summary_line.to_s.chomp()).to eq(test_output_line.to_s.chomp())
                test_object.dlg("Passed(#{cur_summary_line.to_s})", 6)
                cur_idx             += 1
            end
        }

      end
  end

  describe "full summary using the file input arg"
    context "try to run all test input file simulations" do
      it "will validate the input files match the expected output" do

        # Build out the test file array by assuming the test files have a prefix and numbering convention
        test_files                  = []
        test_file_dir               = "./spec"
        Dir.glob(test_file_dir + "/input_*.txt") { |file|
            input_file_name         = ""
            output_file_name        = ""
        
            if file.include?("input")
                new_node            = {
                                    "Input"     => "Not Real",
                                    "Output"    => "Not Real"
                                    }
                input_file_name     = file.to_s
                new_node["Input"]   = input_file_name
                new_node["Output"]  = test_file_dir + "/output_" + input_file_name.split("_")[1]
                test_files.push(new_node)
            end
        }

        # For each test file make sure to rebuild the PaymentProcessor and simulate the input to verify that it
        # matches the output
        test_files.each{ |test| 

            test_input_file         = test["Input"]
            test_output_file        = test["Output"]
            cur_file_suffix         = test["Input"].split("_")[1]

            test_object             = PaymentProcessor.new()

            test_output_lines       = []
            File.open(test_output_file, "r") { |outputfile|
                outputfile.each_line { |test_output_line|
                    test_output_lines.push(test_output_line)
                }
            }

            # run the command and generate the temp files by overwriting to disk at: /tmp
            generated_output_file   = "/tmp/output_#{cur_file_suffix}"

            # clean up any old test output:
            system("rm -f #{generated_output_file}")
            
            # run it:
            system("pushd ./lib >> /dev/null && ruby ./run_processor.rb .#{test_input_file} > #{generated_output_file}")

            summary_lines           = []
            File.open(generated_output_file, "r") { |generated_output_file|
                generated_output_file.each_line { |generated_output_line|
                    summary_lines.push(generated_output_line)
                }
            }
            
            expect(summary_lines.length).to eq(test_output_lines.length)

            cur_idx                 = 0
            while cur_idx < test_output_lines.length
                cur_summary_line    = summary_lines[cur_idx]
                test_output_line    = test_output_lines[cur_idx]

                expect(cur_summary_line.to_s.chomp()).to eq(test_output_line.to_s.chomp())
                test_object.dlg("Passed(#{cur_summary_line.to_s})", 6)
                cur_idx             += 1
            end
            system("rm -f #{generated_output_file}")
        }

      end
  end

  describe "full summary using the stdin input"
    context "try to run all test input file simulations" do
      it "will validate the input files match the expected output" do

        # Build out the test file array by assuming the test files have a prefix and numbering convention
        test_files                  = []
        test_file_dir               = "./spec"
        Dir.glob(test_file_dir + "/input_*.txt") { |file|
            input_file_name         = ""
            output_file_name        = ""
        
            if file.include?("input")
                new_node            = {
                                    "Input"     => "Not Real",
                                    "Output"    => "Not Real"
                                    }
                input_file_name     = file.to_s
                new_node["Input"]   = input_file_name
                new_node["Output"]  = test_file_dir + "/output_" + input_file_name.split("_")[1]
                test_files.push(new_node)
            end
        }

        # For each test file make sure to rebuild the PaymentProcessor and simulate the input to verify that it
        # matches the output
        test_files.each{ |test| 

            test_input_file         = test["Input"]
            test_output_file        = test["Output"]
            cur_file_suffix         = test["Input"].split("_")[1]

            test_object             = PaymentProcessor.new()

            test_output_lines       = []
            File.open(test_output_file, "r") { |outputfile|
                outputfile.each_line { |test_output_line|
                    test_output_lines.push(test_output_line)
                }
            }

            # run the command and generate the temp files by overwriting to disk at: /tmp
            generated_output_file   = "/tmp/catoutput_#{cur_file_suffix}"
            
            # clean up any old test output:
            system("rm -f #{generated_output_file}")

            # run it:
            system("pushd ./lib >> /dev/null && cat .#{test_input_file} | ruby ./run_processor.rb > #{generated_output_file}")

            summary_lines           = []
            File.open(generated_output_file, "r") { |generated_output_file|
                generated_output_file.each_line { |generated_output_line|
                    summary_lines.push(generated_output_line)
                }
            }
            
            expect(summary_lines.length).to eq(test_output_lines.length)

            cur_idx                 = 0
            while cur_idx < test_output_lines.length
                cur_summary_line    = summary_lines[cur_idx]
                test_output_line    = test_output_lines[cur_idx]

                expect(cur_summary_line.to_s.chomp()).to eq(test_output_line.to_s.chomp())
                test_object.dlg("Passed(#{cur_summary_line.to_s})", 6)
                cur_idx             += 1
            end
            system("rm -f #{generated_output_file}")
        }

      end
  end

end

