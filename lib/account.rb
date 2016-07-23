#--
#
# Author::    Jay Johnson 
# Copyright:: Copyright (c) 2015 Jay Johnson
# License::   Distributes under the same terms as Ruby
#
#++

require 'card'
require 'logging'

# 
# This Account implementation is a standalone class and uses
# the associated member variables to track a user's account balance,
# account limit, credit cards, and default payment source.
#
# It also uses the logging helper methods: lg_helper and dlg_helper
# to handle colorize-d logging and abstraction for enhancing rsyslog
# support.
#
class Account

    # 
    # Initializes the Account class to a Valid state by default with
    # no credit cards and no default payment source
    #
    # name - new name for this Account
    # debug - internal debug flag used for testing
    #
    def initialize(name, debug=false)
        @name               = name
        @cards              = {}
        @account_balance    = 0.0
        @account_limit      = 0.0

        @default_source     = "-1"
        @status             = "Valid"

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
    # This method gets the default payment source associated to the account.
    # Right now the current implementation and input/output files do not specify
    # handling support for choosing which payment source to show in the summary.
    # I am taking a shot here that this is the anticipated enhancements.
    #
    def get_default_source()

        # if there's cards on the account, and there's a default source that is valid
        if @cards.length > 0 and @default_source.to_s != "-1" and @cards[@default_source].is_valid()

            dlg("Found Cards(#{@cards.length.to_s}) Default(#{@default_source.to_s})", 6)

            # Get the default source by looking up the card number
            if @cards.has_key?(@default_source)
                dlg("Found Cards(#{@cards.length.to_s}) Default(#{@default_source.to_s})", 6)
                return @cards[@default_source]
            else
                dlg("Failed to find default source(#{@default_source})", 6)
            end 
                
            # if there is no default source that was found in the +@cards+ hash, then return an invalid
            # Card object
            return Card.new("1000000000000000", 0)
        else
            # Return an invalid Card object to handle cases where the simulation tries to do something
            # to an Account without a +@defaultsource+
            return Card.new("2000000000000000", 0)
        end
    end

    #
    # This method gets the account balance. It is a stub for a possible future enhancement.
    #
    def get_account_balance()
        return @account_balance
    end 

    #
    # This method gets the account limit. It is a stub for a possible future enhancement.
    #
    def get_account_limit()
        return @account_limit
    end 

    #
    # This method sets the account balance. It is a stub for a possible future enhancement.
    #
    # new_balance - new float balance for the account
    #
    def set_account_balance(new_balance)
        dlg("New Balance(#{new_balance.to_s})", 6)
        @account_balance    = new_balance
    end

    #
    # This method sets the account limit. It is a stub for a possible future enhancement.
    #
    # new_limit - new float limit for the account
    #
    def set_account_limit(new_limit)
        dlg("New Limit(#{new_limit.to_s})", 6)
        @account_limit      = new_limit
    end

    #
    # This method allows for enforcing business-specific rules and conditions for
    # how an Account handles balance and limit cases. It is a stub for a possible future enhancement.
    #
    # card_num - credit card number
    # new_balance - new balance to screen for fraud, errors, or other checks
    #
    def check_balance_conditions(card_num, new_balance)
        dlg("New Balance(#{new_balance.to_s})", 6)
        @account_balance    = new_balance
    end

    #
    # This method parses the assigned format from the SPEC to a supported float for use across
    # Account and Card objects. It is defensively coded to prevent errors.
    #
    # amount_str - string in the format of $AAA like $500 that is converted to a float
    #
    def convert_amount_to_float(amount_str)
        begin
            float_amount    = amount_str[1..-1].to_f
            return float_amount
        rescue Exception
            return 0
        end
    end

    # 
    # This method is a stub that allows for checking business rules that would
    # define how a card can be activated/promoted to the default payment source
    # for a recurring (monthly/daily) billing payment service.
    #
    # card_str - holds the new card for eligibility testing
    # debug - internal debug flag for this method
    #
    def set_default_source(card_str, debug=false)
        puts "Stub for handling changing the default source"
    end

    # 
    # This method is one of the required commands that adds a new Card object to 
    # the Account object's +@cards+ hash. If the card is invalid (for whatever reason)
    # the Account is put into an "error" status. If the card is valid then it 
    # becomes the default payment source +@defaultsource+.
    #
    # card_str - new card number must be between 13 and 19 characters
    # limit_str - new card limit in the format of $AAA for example $100
    # debug - internal debug flag for this method
    #
    def add(card_str, limit_str, debug=false)

        begin

            # convert the string to a valid float
            limit       = self.convert_amount_to_float(limit_str)

            # Create the new Card that will check for a valid Luhn 10 
            # and other conditions in the future.
            dlg("Creating Card(#{card_str})", 6)
            new_card    = Card.new(card_str, limit)

            # if the card pass all security and fraud screens 
            if new_card.is_valid()
            
                # Add it to the Account +@cards+ hash
                dlg("Add - Account(#{@name}) Adding Valid Card(#{card_str})", 6)
                @cards[card_str]        = new_card

                # is this the first valid card 
                if @default_source.to_s == "-1"
                    @account_balance    = 0.0
                    @account_limit      = 0.0
                    
                    dlg("New Default Source(#{card_str}) DS(#{@default_source.to_s})", 6)
                end
                    
                # Assign it to the default source
                @default_source     = card_str
                @status             = "Valid"

            # if not a valid card this account is now in an error state
            else
                dlg("Card(#{card_str}) Failed(#{new_card.get_status()})", 6)
                @default_source     = "-1"
                @status             = "error"
            end
        rescue Exception => e
            dlg("ERROR: Card(#{card_str}) with Ex(#{e.message})", 0)
        end

    end

    # 
    # This method is one of the required commands that credits a Card (if it exists).
    #
    # amount_str - the integer amount formatted as $AAA to credit to the card's balance
    # card_str - stub for changing the card to credit instead of the default source.
    #            By default "0" implies to use the +@defaultsource+ if there is one.
    # debug - internal debug flag for this method
    #
    def credit(amount_str, card_str="0", debug=false)
        status  = 1

        # are there any cards to check
        if @cards.length > 0

            # convert the str amount to a float
            amount          = self.convert_amount_to_float(amount_str)

            dlg("Name(#{@name}) Cards(#{@cards.length})", 5)
            
            # default to 'did not find a card' case
            target_card     = nil

            # determine the target card - this is a stub for extending support to find non-default sources by
            # the card number
            if @default_source.to_s != "-1" and card_str == "0" and @cards[@default_source].is_valid()
                target_card = @cards[@default_source]
            else

                # if there is a card_str and there's a matching card already on the Account that is valid
                if @cards.has_key?(card_str)
                    if @cards[card_str].is_valid()
                        dlg(" - Crediting Name(#{@name}) Card(#{card_str})", 5)
                        target_card = @cards[card_str]
                    else
                        dlg("ERROR: Name(#{@name}) Does not have Valid Card(#{card_str})", 0)
                    end
                else
                    dlg("ERROR: Name(#{@name}) Does not have Card(#{card_str})", 0)
                end
            end
            
            # if there is a Card object try to credit the balance
            if target_card == nil
                return status
            else
                dlg(" - Crediting Name(#{@name}) DS(#{@default_source}) Balance(#{target_card.get_balance()}) Amount(#{amount})", 5)
                return target_card._credit_helper(amount)
            end

        else
            dlg("ERROR: Account(#{@name}) has no valid credit cards", 0)
        end
                        
        return status
    end
    
    # 
    # This method is one of the required commands that charges a Card (if it exists).
    #
    # amount_str - the integer amount formatted as $AAA to charge to the card's balance
    # card_str - stub for changing the card to charge instead of the default source.
    #            By default "0" implies to use the +@defaultsource+ if there is one.
    # debug - internal debug flag for this method
    #
    def charge(amount_str, card_str="0", debug=false)
        status  = 1

        # are there any cards to check
        if @cards.length > 0

            # convert the str amount to a float
            amount      = self.convert_amount_to_float(amount_str)

            dlg("Name(#{@name}) Cards(#{@cards.length}) Amount(#{amount})", 5)

            # default to 'did not find a card' case
            target_card = nil

            # determine the target card - this is a stub for extending support to find non-default sources by
            # the card number
            if @default_source.to_s != "-1" and card_str == "0" and @cards[@default_source].is_valid()
                target_card         = @cards[@default_source]
            else

                # if there is a card_str and there's a matching card already on the Account that is valid
                if @cards.has_key?(card_str)
                    if @cards[card_str].is_valid()
                        dlg(" - Charging Name(#{@name}) Card(#{card_str})", 5)
                        target_card = @cards[card_str]
                    else
                        dlg("ERROR: Name(#{@name}) Does not have Valid Card(#{card_str})", 0)
                    end
                else
                    dlg("ERROR: Name(#{@name}) Does not have Card(#{card_str})", 0)
                end
            end

            # if there is a Card object try to charge the balance
            if target_card == nil
                return status
            else
                dlg(" - Charging Name(#{@name}) DS(#{@default_source}) Balance(#{target_card.get_balance()}) Amount(#{amount})", 5)
                status = target_card._charge_helper(amount)
            end

        else
            dlg("ERROR: Account(#{@name}) has no valid credit cards", 0)
        end
                        
        return status
    end

    # 
    # This method gets the +@name+ member
    #
    # returns - +@name+
    #
    def get_name()
        @name
    end

    # 
    # This method gets the +@cards+ member
    #
    # returns - +@cards+
    #
    def get_cards()
        @cards
    end
    
    # 
    # This method gets the +@status+ member
    #
    # returns - +@status+
    #
    def get_status()
        @status
    end

    # 
    # This method tests if the Account is in a valid +@status+ and there is at least 1 +@cards+ Card on this Account
    #
    # returns - true if valid, false if not
    #
    def is_valid?()
        @status == "Valid" and @cards.length > 0
    end

end

