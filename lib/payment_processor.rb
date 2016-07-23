#--
#
# Author::    Jay Johnson 
# Copyright:: Copyright (c) 2015 Jay Johnson
# License::   Distributes under the same terms as Ruby
#
#++

require 'account'
require 'logging'

# 
# This Payment Processor implementation is a standalone class and uses
# the associated member variables to track Accounts, drive processing, and
# run the final summary report.
#
# It also uses the logging helper methods: lg_helper and dlg_helper
# to handle colorize-d logging and abstraction for enhancing rsyslog
# support.
#
class PaymentProcessor

    # 
    # Initializes the PaymentProcessor class 
    # By default there are no accounts
    #
    # debug - internal debug flag used for testing
    #
    def initialize(debug=false)
        @accounts           = {}

        @debug_accounts     = false
        @debug_cards        = false
        @debug              = debug
    end

    # 
    # Wrapper for the lg_helper to log the msg at the appropriate
    # log level enumeration. For now the associated log stream is stdout.
    #
    # msg - the string message to log
    # level - the log level enumeration for enhancing to rsyslog
    # debug - defaults to false, ignored for now
    # 
    def lg(msg, level=6, debug=false)
        lg_helper(msg, level)
    end
    
    # 
    # Wrapper for the dlg_helper class that handles checking if the
    # +@debug+ variable for the class is +true+. If the @debug is false
    # the method does nothing, but if the @debug is true it will log 
    # to the associated log stream (stdout for now).
    #
    # msg - the string message to log
    # level - the log level enumeration for enhancing to rsyslog
    # 
    def dlg(msg, level=6)
        dlg_helper(msg, level, @debug)
    end

    # 
    # Allow for dynamic enabling of +@debug+
    # 
    def enable_debug()
        @debug              = true
    end

    # 
    # Drives Adding an Account (if it does not exist) and adding the new Card. Storage of
    # Account objects handled by +name+ as a hash in the +@accounts+ member variable.
    #
    # name - new Account name
    # new_card_str - new Card's number
    # limit_str - string representation for the new starting limit if the Card is valid
    # debug - internal debug flag for this method
    #
    # returns - 1 if failed, 0 if success
    #
    def add(name, new_card_str, limit_str, debug=false)
        
        status  = 1

        # is there an existing account
        if @accounts.has_key?(name)
            dlg("Already have Account(#{name})", 6)
        else
            dlg("Add - Creating Account Name(#{name}) Card(#{new_card_str}) Limit(#{limit_str})", 6)
        
            # Create the Account object
            @accounts[name]  = Account.new(name, @debug_accounts)
        end

        # Does the Account have this card already
        if @accounts[name].get_cards().has_key?(new_card_str) == false
            dlg("\tCreating Card(#{new_card_str})", 6)

            # Create an run security screens on the Card
            status  = @accounts[name].add(new_card_str, limit_str)
        else
            dlg("\tAccount(#{name}) already has Card(#{new_card_str})", 6)
        end

        return status
    end

    # 
    # Drives Crediting an Account (if it exists) and crediting the amount to the Card's balance.
    #
    # name - existing Account name
    # amount_str - string representation for the new starting limit if the Card is valid
    # new_card_str - targeting of a non-default Card's number to credit, by default "0" means use 
    #               the default source for the Account
    # debug - internal debug flag for this method
    #
    # returns - 1 if failed, 0 if success
    #
    def credit(name, amount_str, new_card_str="0", debug=false)

        status  = 1

        # if there is an Account object
        if @accounts.has_key?(name)
            status  = @accounts[name].credit(amount_str, new_card_str, debug)
        else
            dlg("No Account(#{name})", 6)
        end

        return status
    end

    # 
    # Drives Charge an Account (if it exists) and charging the amount to the Card's balance.
    #
    # name - existing Account name
    # amount_str - string representation for the new starting limit if the Card is valid
    # new_card_str - targeting of a non-default Card's number to credit, by default "0" means use 
    #               the default source for the Account
    # debug - internal debug flag for this method
    #
    # returns - 1 if failed, 0 if success
    #
    def charge(name, amount_str, new_card_str="0", debug=false)

        status  = 1
        
        # if there is an Account object
        if @accounts.has_key?(name)
            status  = @accounts[name].charge(amount_str, new_card_str, debug)
        else
            dlg("No Account(#{name})", 6)
        end

        return status
    end

    # 
    # Drives Factory style handling for commands that are parsed and handled according
    # to the Specification. Split the incoming +org_line+ parameter into an array, process the
    # first command argument cell and execute the method associated to the string representation.
    #
    # org_line - input command line string that can be any of the allowed commands outlined
    #            in the SPEC.
    # debug - internal debug flag for this method
    #
    def process_action(org_line, debug=false)

        # make sure to turn it into a line and chomp the newline and whitespace chars
        line    = org_line.to_s.chomp()
        dlg("Process(#{line})", 6)

        # split this new string into an array of arguments to process
        args    = line.split(" ")

        # were there any arguments
        if args.length > 0

            # Handle Add:
            #   Add Greg 4111111111111111 $1000
            if    args[0] == "Add"

                # Make sure to confirm the Add command had the exact allowed number of arguments
                if args.length == 4
                    self.add(args[1].to_s, args[2].to_s, args[3].to_s, debug)
                else
                    lg("ERROR: Add - Unsupported Number of Arguments(#{args}) Length(#{args.length})", 0)
                end

            # Handle Charge:
            #   Charge Greg $500
            elsif args[0] == "Charge"
                if args.length == 3
                
                    # Make sure to confirm the Charge command had the exact allowed number of arguments
                    self.charge(args[1].to_s, args[2].to_s, "0", debug)
                else
                    lg("ERROR: Charge - Unsupported Number of Arguments(#{args}) Length(#{args.length})", 0)
                end
            # Handle Credit:
            #   Credit Karla $100
            elsif args[0] == "Credit"
                if args.length == 3

                    # Make sure to confirm the Credit command had the exact allowed number of arguments
                    self.credit(args[1].to_s, args[2].to_s, "0", debug)
                else
                    lg("ERROR: Credit - Unsupported Number of Arguments(#{args}) Length(#{args.length})", 0)
                end
            else
                lg("ERROR: Unsupported Action(#{args[0]})", 0)
            end
        else
            lg("ERROR: Missing Action(#{org_line})", 0)
        end
    end

    # 
    # Drives the Summary method for creating the SPEC summary at the end of this simulation.
    #
    # debug - internal debug flag for this method
    #
    # returns - +summary_report+ holding the entire output for this simulation
    #
    def run_report(debug=false)

        summary_report  = ""
        dlg("\n\n", 6)
        dlg("Report: Accounts(#{@accounts.length})", 6)
        dlg("", 6)

        # Sort the accounts and iterate over each named Account
        Hash[@accounts.sort].each do |name,acc|

            cur_line    = "\n"

            # if the account is valid 
            if acc.is_valid? == true
                if debug
                    dlg("\tAccount(#{name}) Cards(#{acc.get_cards().length}) Balance(#{acc.get_default_source().get_balance()}) Limit(#{acc.get_limit()})", 6)
                end
                dlg("#{name}: $#{acc.get_default_source().get_balance().to_i}", 6)

                # Build the appropriate output for the Account's balance
                cur_line    = "#{name}: $#{acc.get_default_source().get_balance().to_i}\n"
            else
                if debug
                    dlg("\tAccount(#{name}): #{acc.get_status()}", 6)
                end
                dlg("#{name}: #{acc.get_status()}", 6)
                
                # Build the appropriate output for the Account's balance
                cur_line    = "#{name}: #{acc.get_status()}\n"
            end
        
            # add this new line to the summary report
            summary_report  += cur_line

        end
        dlg("\n\n", 6)

        summary_report
    end

end


